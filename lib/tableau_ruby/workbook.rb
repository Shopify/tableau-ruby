require 'base64'

module Tableau
  class Workbook

    def initialize(client)
      @client = client
    end

    def all(params={})
      return { error: "user_id is missing." } if params[:user_id].nil? || params[:user_id].empty?

      resp = @client.conn.get "/api/2.0/sites/#{@client.site_id}/users/#{params[:user_id]}/workbooks" do |req|
        req.params['getThumbnails'] = params[:include_images] if params[:include_images]
        req.params['isOwner'] = params[:is_owner] || false
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {workbooks: [], pagination: {}}
      doc = Nokogiri::XML(resp.body)

      doc.css("pagination").each do |p|
        data[:pagination][:page_number] = p['pageNumber']
        data[:pagination][:page_size] = p['pageSize']
        data[:pagination][:total_available] = p['totalAvailable']
      end

      doc.css("workbook").each do |w|
        workbook = {id: w["id"], name: w["name"]}

        if params[:include_images]
          resp = @client.conn.get("/api/2.0/sites/#{@client.site_id}/workbooks/#{w['id']}/previewImage") do |req|
            req.headers['X-Tableau-Auth'] = @client.token if @client.token
          end
          workbook[:image] = Base64.encode64(resp.body)
          workbook[:image_mime_type] = "image/png"
        end

        w.css('project').each do |p|
          workbook[:project] = {id: p['id'], name: p['name']}
        end

        w.css("tag").each do |t|
          (workbook[:tags] ||=[]) << t['id']
        end

        if params[:include_views]
          workbook[:views] = include_views(site_id: @client.site_id, id: w['id'])
        end

        data[:workbooks] << workbook
      end
      data
    end

    def find(params)
      resp = @client.conn.get "/api/2.0/sites/#{params[:site_id]}/workbooks/#{params[:workbook_id]}" do |req|
        req.params['previewImage'] = params[:preview_images] if params[:preview_images]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {}
      Nokogiri::XML(resp.body).css("workbook").each do |w|

        wkbk = {id: w["id"], name: w["name"], description: w['description']}

        if params[:include_views]
          wkbk[:views] = include_views(site_id: params[:site_id], id: params[:workbook_id])
        end

        data = wkbk
      end

      data
    end

    # TODO: Refactor this is duplicate in all method. Also, there are many, many places that are begging to be DRYer.
    def preview_image(workbook)
      resp = @client.conn.get("/api/2.0/sites/#{params[:site_id]}/workbooks/#{workbook[:id]}/previewImage") do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {}
      data[:image] = Base64.encode64(resp.body)
      data[:image_mime_type] = "image/png"

      data.to_json
    end

    private

    def include_views(params)
      resp = @client.conn.get("/api/2.0/sites/#{params[:site_id]}/workbooks/#{params[:id]}/views") do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      Nokogiri::XML(resp.body).css("view").each do |v|
        (@views ||= []) << {id: v['id'], name: v['name']}
      end

      @views
    end

  end
end
