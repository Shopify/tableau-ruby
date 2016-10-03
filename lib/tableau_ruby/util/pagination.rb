module Tableau
  module Util
    module Pagination
      def paginate_over_all_records(resource, options)
        page = 1
        options.update({page_size: 1000, page_number: page})

        response = get(options)
        data = response
        while data[resource].size < response[:pagination][:total_available].to_i
          page += 1
          response = get(options.update(page_number: page))
          data[resource].concat(response[resource])
        end
        data.delete(:pagination)
        data
      end
    end
  end
end
