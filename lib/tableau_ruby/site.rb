module Tableau
  class Site

    def initialize(client)
      @client = client
    end

    def all(params={})
      resp = @client.conn.get "/api/2.0/sites" do |req|
        req.params['includeProjects'] = params[:include_projects]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      data = {sites: []}
      Nokogiri::XML(resp.body).css("tsResponse sites site").each do |s|
        s.css("project").each do |p|
          (@projects ||= []) << {id: p["id"], name: p["name"]}
        end
        data[:sites] << normalize_json(s)
      end
      data
    end

    def find_by(params={})
      if params.include? :name && params[:name].nil? || params[:name].gsub(" ", "").empty?
        return { error: "site name is missing." }.to_json
      elsif params.include? :id && params[:id].nil? || params[:id].gsub(" ", "").empty?
        return { error: "site id is missing." }.to_json
      end
      key = params.keys - [:include_projects]
      term = params[key[0]]
      resp = @client.conn.get "/api/2.0/sites/#{term}" do |req|
        req.params['includeProjects'] = params[:include_projects] || false
        req.params["key"] = "name" if term == params[:name]
        req.params["key"] = "contentUrl" if term == params[:url]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      normalize_json(Nokogiri::XML(resp.body).css("site").first)
    end

    def create(site)
      return { error: "site name is missing." }.to_json unless site[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.site(
            name: site[:name] || 'New Site',
            contentUrl: site[:url] || site[:name],
            adminMode: site[:admin_mode] || 'ContentAndUsers',
            userQuota: site[:user_quota] || '100',
            storageQuota: site[:storage_quota] || '20',
            disableSubscriptions: site[:disable_subscriptions] || false
          )
        end
      end

      resp = @client.conn.post "/api/2.0/sites" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      if resp.status == 201
        normalize_json(resp.body)
      else
        {error: resp.status}.to_json
      end
    end

    def update(site)
      return { error: "site id is missing." }.to_json unless site[:id]

      case_dict = {
        name: "name",
        content_url: "contentUrl",
        admin_mode: "adminMode",
        user_quota: "userQuota",
        storage_quota: "storageQuota",
        disable_subscriptions: "disableSubscriptions"
      }

      site.each do |k,v|
        next if k == :id
        (@site ||= {}).store(case_dict[k],v)
      end

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.site(@site)
        end
      end

      resp = @client.conn.put "/api/2.0/sites/#{site[:id]}" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      normalize_json(resp.body)
    end

    def delete(site)
      return { error: "site id is missing." }.to_json unless site[:id]

      resp = @client.conn.delete "/api/2.0/sites/#{site[:id]}" do |req|
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      if resp.status == 204
        {success: 'Site successfully deleted.'}.to_json
      else
        {errors: resp.status}.to_json
      end
    end

    private

    def normalize_json(s)
      {
        name: s['name'],
        id: s['id'],
        content_url: s['contentUrl'],
        admin_mode: s['adminMode'],
        user_quota: s['userQuota'],
        storage_quota: s['storageQuota'],
        state: s['state'],
        status_reason: s['statusReason']
      }
    end
  end
end
