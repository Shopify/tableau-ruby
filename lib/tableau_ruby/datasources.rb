
require 'base64'
require 'securerandom'

module Tableau
  class Datasources
    include Util::Permissions

    def initialize(client)
      @client = client
    end

    def create(params = {})
      params[:site_id] ||= @client.site_id
      db_user = params[:db_user]
      db_pass = params[:db_pass]


      raise "Missing datasource file!" unless params[:file_path] || 
          (params[:file] && params[:file][:name] && params[:file][:data])
      raise "Missing site-id" unless params[:site_id]
      raise "Missing project id" unless params[:project_id]

      if params[:file]
        filename = params[:file][:name]
        filedata = params[:file][:data]
      else
        filename = params[:file_path].split("/").last
        filedata = File.read(params[:file_path])
      end

      name = params[:name] || filename.gsub(".tds","").gsub(" ", "")

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.datasource(name: name) do
            xml.connectionCredentials(name: db_user, password: db_pass, embed: true)
            xml.project(id: params[:project_id])
          end
        end
      end

      payload = builder.doc.root.to_xml#(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
      multipart_body = <<-BODY
--boundary-string
Content-Disposition: name="request_payload"
Content-Type: text/xml

#{payload}
--boundary-string
Content-Disposition: name="tableau_datasource"; filename="#{filename}"
Content-Type: application/octet-stream

#{filedata}
--boundary-string--
BODY

      multipart_body.gsub!("\n","\r\n")

      resp = @client.conn.post("/api/2.0/sites/#{params[:site_id]}/datasources") do |req|
        req.params["overwrite"] = true
        req.headers["Content-Type"] = "multipart/mixed; boundary=\"boundary-string\""
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
        req.body = multipart_body
      end

      raise resp.body if resp.status > 299
      Nokogiri::XML(resp.body).css("datasource").collect do |w|
        { id: w["id"], name: w["name"], type: w['type'], 
          owner: { id: w.css('owner').first['id']},
          project: { id: w.css('project').first['id'], name: w.css('project').first['name']},
          tags: w.css('tags tag').collect{|v|
            {label: v['label']}
          }
        }
      end.first
    end

    def all(params={})
      resp = @client.conn.get "/api/2.0/sites/#{@client.site_id}/datasources?pageSize=1000" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {datasources: [], pagination: {}}
      doc = Nokogiri::XML(resp.body)

      doc.css("pagination").each do |p|
        data[:pagination][:page_number] = p['pageNumber']
        data[:pagination][:page_size] = p['pageSize']
        data[:pagination][:total_available] = p['totalAvailable']
      end

      doc.css("datasource").each do |w|
        workbook = {id: w["id"], name: w["name"], type: w['type']}

        w.css('project').each do |p|
          workbook[:project] = {id: p['id'], name: p['name']}
        end

        w.css("tag").each do |t|
          (workbook[:tags] ||=[]) << t['id']
        end

        data[:datasources] << workbook
      end
      data
    end

    def find(params)

      all_ds = all

      if params[:name]
        return all_ds[:datasources].select {|x| x[:name] == params[:name]}.first
      elsif params[:id]
        return all_ds[:datasources].select {|x| x[:id] == params[:id]}.first
      end
    end

    def add_permissions_for_user(params)
      # params => {
      #   :datasource_id => 'cf68994e-29c8-4f41-bf6c-398e3666131e' },
      #   :user_id => 'cf68994e-29c8-4f41-bf6c-398e3666131e'}
      #   :permissions => [
      #     :allow =>  ['Read', 'ExportImage', 'ExportData'],
      #     :deny => ['ViewComments', 'AddComment', 'Filter', 'Connect']
      #   ]
      # }
      return { error: "datasource id is missing." } unless params[:datasource_id]
      return { error: "site id is missing." } unless @client.site_id
      return { error: "user id is missing."} unless params[:user_id]

      site_id = @client.site_id

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.permissions do
            xml.datasource(id: params[:datasource_id])
            build_permissions_for_user(xml, params)
          end
        end
      end

      resp = @client.conn.put "/api/2.0/sites/#{site_id}/datasources/#{params[:datasource_id]}/permissions" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      Nokogiri::XML(resp.body)
    end
  end
end
