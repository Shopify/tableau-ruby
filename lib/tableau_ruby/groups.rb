module Tableau
  class Groups
    def initialize(client)
      @client = client
    end

    def all
      resp = @client.conn.get "/api/2.2/sites/#{@client.site_id}/groups" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      groups = {groups: []}
      Nokogiri::XML(resp.body).css("tsResponse groups group").each do |s|
        groups[:groups] << {id: s["id"], name: s["name"]}
      end
      groups
    end

    def all_users_group
      all[:groups].detect{|group| group[:name] == "All Users"}
    end
  end
end