module Tableau
  class Users
    include Util::Pagination

    attr_reader :workbooks

    def initialize(client)
      @client = client
    end

    def create(options)
      site_id = options[:site_id] || @client.site_id
      site_role = options[:siteRole] || "Interactor"

      return { error: "name is missing." } unless options[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.user(
            name: options[:name],
            siteRole: site_role
          )
        end
      end

      resp = @client.conn.post "/api/2.0/sites/#{site_id}/users" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      Nokogiri::XML(resp.body).css("tsResponse user").each do |s|
        return s["id"]
      end
    end

    def update(options)
      site_id = options[:site_id] || @client.site_id

      return { error: "user id is missing." } unless options[:user_id]
      user_id = options[:user_id]

      options.delete(:user_id)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.user(options)
        end
      end
  
      resp = @client.conn.put "/api/2.0/sites/#{site_id}/users/#{user_id}" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      return resp.status
    end

    def delete(options)
      site_id = options[:site_id] || @client.site_id

      return { error: "user_id is missing." } unless options[:user_id]

      resp = @client.conn.delete "/api/2.0/sites/#{site_id}/users/#{options[:user_id]}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      return resp.status
    end

    def get(options={})
      site_id = @client.site_id

      params = {pageSize: options[:page_size] || ''}
      params.merge!(pageNumber: options[:page_number]) if options[:page_number]

      resp = @client.conn.get "/api/2.0/sites/#{site_id}/users", params do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {users: [], pagination: {}}

      doc = Nokogiri::XML(resp.body)
      doc.css("tsResponse users user").each do |u|
        data[:users] << {
          id: u['id'],
          name: u['name'],
          site_id: site_id,
          role: u['role'],
          publish: u['publish'],
          content_admin: u['contentAdmin'],
          last_login: u['lastLogin'],
          external_auth_user_id: u['externalAuthUserId']
        }
      end

      doc.css("pagination").each do |p|
        data[:pagination][:page_number] = p['pageNumber']
        data[:pagination][:page_size] = p['pageSize']
        data[:pagination][:total_available] = p['totalAvailable']
      end
      data
    end

    def all(options={})
      paginate_over_all_records(:users, options)
    end

    def find_by(params={})
      records = all()[:users]
      if params[:id]
        return records.select {|u| u[:id] == params[:id] }.first
      elsif params[:name]
        return records.select {|u| u[:name] == params[:name] }.first
      else
        raise "You need :id or :name"
      end
    end


    private

    def normalize(r, site_id, name=nil)
      data = {user: {}}
      Nokogiri::XML(r).css("user").each do |u|
        data[:user] = {
          id: u['id'],
          name: u['name'],
          site_id: site_id,
          role: u['role'],
          publish: u['publish'],
          content_admin: u['contentAdmin'],
          last_login: u['lastLogin'],
          external_auth_user_id: u['externalAuthUserId']
        }
        return data if !name.nil? && name == u['name']
      end
      data
    end

  end
end
