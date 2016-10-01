module Tableau
  class Project
    include Util::Permissions

    def initialize(client)
      @client = client
    end

    def all
      resp = @client.conn.get "/api/2.2/sites/#{@client.site_id}/projects" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      projects = {projects: []}
      Nokogiri::XML(resp.body).css("tsResponse projects project").each do |s|
        projects[:projects] << {id: s["id"], name: s["name"]}
      end
      projects
    end

    def find_by(params)
      site_id = params[:site_id] || @client.site_id

      all[:projects].select{|proj| proj[:name] == params[:name] }.first
    end

    def create(project)
      site_id = project[:site_id] || @client.site_id
      return { error: "name is missing." } unless project[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.project(
            name: project[:name],
            description: project[:description]
          )
        end
      end

      resp = @client.conn.post "/api/2.2/sites/#{site_id}/projects" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      Nokogiri::XML(resp.body).css("tsResponse project").each do |s|
        return s["id"]
      end
    end

    def update(project)
      return { error: "site_id is missing." } unless project[:site_id]
      return { error: "name is missing." } unless project[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.project(
            name: project[:name],
            description: project[:description]
          )
        end
      end

      resp = @client.conn.put "/api/2.2/sites/#{project[:site_id]}/projects/#{project[:project_id]}" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      if resp.status == 200
        {project: resp.body}
      else
        {error: resp.status}
      end
    end


    def delete(project)
      site_id = project[:site_id] || @client.site_id

      return { error: "project id is missing." } unless project[:id]

      resp = @client.conn.delete "/api/2.2/sites/#{site_id}/projects/#{project[:id]}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      true
    end

    def add_permissions_for_group(params)
      # params => {
      #   :project_id => 'cf68994e-29c8-4f41-bf6c-398e3666131e' },
      #   :group_id => 'cf68994e-29c8-4f41-bf6c-398e3666131e'}
      #   :permissions => [
      #     :allow =>  ['Read', 'ExportImage', 'ExportData'],
      #     :deny => ['ViewComments', 'AddComment', 'Filter', 'Connect']
      #   ]
      # }
      return { error: "project id is missing." } unless params[:project_id]
      return { error: "site id is missing." } unless @client.site_id

      # get the group id
      params[:group_id] = @client.groups.all_users_group[:id]
      return { error: "group id is missing."} unless params[:group_id]

      site_id = @client.site_id

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.permissions do
            xml.project(id: params[:project_id])
            build_permissions_for_group(xml, params)
          end
        end
      end

      resp = @client.conn.put "/api/2.2/sites/#{site_id}/projects/#{params[:project_id]}/permissions" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      Nokogiri::XML(resp.body)
    end

    def add_permissions_for_user(params)
      # params => {
      #   :project_id => 'cf68994e-29c8-4f41-bf6c-398e3666131e' },
      #   :user_id => 'cf68994e-29c8-4f41-bf6c-398e3666131e'}
      #   :permissions => [
      #     :allow =>  ['Read', 'ExportImage', 'ExportData'],
      #     :deny => ['ViewComments', 'AddComment', 'Filter', 'Connect']
      #   ]
      # }
      return { error: "project id is missing." } unless params[:project_id]
      return { error: "site id is missing." } unless @client.site_id
      return { error: "user id is missing."} unless params[:user_id]

      site_id = @client.site_id

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.permissions do
            xml.project(id: params[:project_id])
            build_permissions_for_user(xml, params)
          end
        end
      end

      resp = @client.conn.put "/api/2.2/sites/#{site_id}/projects/#{params[:project_id]}/permissions" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      Nokogiri::XML(resp.body)
    end
  end
end