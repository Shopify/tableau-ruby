module Tableau
  class Users

    attr_reader :workbooks

    def initialize(client)
      @client = client
    end

    def all(params={})
      site_id = @client.site_id

      resp = @client.conn.get "/api/2.0/sites/#{site_id}/users?pageSize=#{params["page-size"]}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {users: []}
      Nokogiri::XML(resp.body).css("tsResponse users user").each do |u|
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
      data
    end

    def find_by(params={})
      params.update({"page-size" => 1000})

      #BUG: if you have more than 1000 users, you wont find your users
      #needs pagination support
      all_users = all(params)[:users]

      return all_users.select {|u| u[:name] == params[:user_name] }.first
    end

    def create(user)
      return { error: "name is missing." }.to_json unless user[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.user(
            name: user[:name] || 'New User',
            role: user[:role] || true,
            publish: user[:publish] || true,
            contentAdmin: user[:content_admin] || false,
            suppressGettingStarted: user[:storage_quota] || false
          )
        end
      end

      resp = @client.conn.post "/api/2.0/sites/#{user[:site_id]}/users" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      if resp.status == 201
        normalize_json(resp.body, user[:site_id])
      else
        {error: { status: resp.status, message: resp.body }}.to_json
      end
    end

    def delete(user)
      return { error: "site_id is missing." }.to_json unless user[:site_id]
      return { error: "user id is missing." }.to_json unless user[:id]

      resp = @client.conn.delete "/api/2.0/sites/#{user[:site_id]}/users/#{user[:id]}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      if resp.status == 204
        {success: 'User successfully deleted.'}.to_json
      else
        {errors: resp.status}.to_json
      end
    end

    private

    def normalize_json(r, site_id, name=nil)
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
        return data.to_json if !name.nil? && name == u['name']
      end
      data.to_json
    end

  end
end
