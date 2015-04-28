require File.dirname(__FILE__) + '/test_helper'

class TestWorkbook < TableauTest
  def test_workbook_listing
    workbooks = @client.workbooks.all(user_id: @admin_user[:id])
    assert workbooks[:workbooks].count > 0
    assert workbooks[:pagination].keys() == [:page_number, :page_size, :total_available]
  end

  def test_workbook_find_by_name
    all_workbooks = @client.workbooks.all(user_id: @admin_user[:id])
    workbook = @client.workbooks.find(site_id: @client.site_id, workbook_id: all_workbooks[:workbooks].first[:id])
    assert workbook[:id]
  end

  def test_workbook_include_views
    all_workbooks = @client.workbooks.all(user_id: @admin_user[:id])
    workbook = @client.workbooks.find(site_id: @client.site_id, workbook_id: all_workbooks[:workbooks].first[:id], include_views: true)
    assert workbook[:id]
    assert workbook[:views]
  end
end
