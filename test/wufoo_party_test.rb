require File.dirname(__FILE__) + '/../lib/wufoo_party'
require 'test/unit'

class WufooPartyTest < Test::Unit::TestCase
  
  def setup
    if ENV['WUFOO_ACCOUNT'] and ENV['WUFOO_API_KEY'] and ENV['WUFOO_FORM_ID']
      @wufoo = WufooParty.new(ENV['WUFOO_ACCOUNT'], ENV['WUFOO_API_KEY'])
      @form_id = ENV['WUFOO_FORM_ID']
    else
      puts 'Must set WUFOO_ACCOUNT, WUFOO_API_KEY and WUFOO_FORM_ID env variables before running.'
      exit(1)
    end
  end
  
  def test_connection
    assert @wufoo.query(@form_id)['form']
  end
  
  def test_submission
    start_count = @wufoo.query(@form_id)['form']['EntryCount'].to_i
    result = @wufoo.submit(@form_id) # blank submission - only works if no required fields
    assert_equal 'true', result['wufoo_submit'][0]['success']
    end_count = @wufoo.query(@form_id)['form']['EntryCount'].to_i
    assert_equal start_count+1, end_count
  end
  
  def test_get_field_numbers
    assert_equal(
      {'1' => ['Name', 'shortname'], '2' => ['Last', 'shortname'], '3' => ['Foo', 'date']},
      @wufoo.get_field_numbers([
        {"Title" => "Name", "Typeof" => "shortname", "SubFields" => [
          {"Title" => "Name", "ColumnId" => "1"},
          {"Title" => "Last", "ColumnId" => "2"}
        ]},
        {"Title" => "Foo", "ColumnId" => "3", "Typeof" => "date"}
      ])
    )
  end
  
end