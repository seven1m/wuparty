require './lib/wuparty'
require 'test/unit'

class WuPartyTest < Test::Unit::TestCase

  # Must create a form called "Test Form" and pass in its id
  # via the ENV variable WUFOO_FORM_ID.
  # Give the form standard name and address fields.
  # Make the name field required.

  def setup
    if ENV['WUFOO_ACCOUNT'] and ENV['WUFOO_API_KEY'] and ENV['WUFOO_FORM_ID']
      @wufoo = WuParty.new(ENV['WUFOO_ACCOUNT'], ENV['WUFOO_API_KEY'])
      @form_id = ENV['WUFOO_FORM_ID']
    else
      puts 'Must set WUFOO_ACCOUNT, WUFOO_API_KEY and WUFOO_FORM_ID env variables before running.'
      exit(1)
    end
  end

  def test_forms
    assert @wufoo.forms
  end

  def test_form
    form = @wufoo.form(@form_id)
    assert form
    assert_equal 'Test Form', form['Name']
  end

  def test_get_form_id
    assert_equal 1, @wufoo.forms.select {|f| f.id == 'test-form'}.length
  end

  def test_form_by_hash
    hash = @wufoo.form(@form_id)['Hash']
    assert @wufoo.form(hash)
  end

  def test_form_directly
    form = WuParty::Form.new(@form_id, :account => ENV['WUFOO_ACCOUNT'], :api_key => ENV['WUFOO_API_KEY'])
    assert_equal 'Test Form', form['Name']
  end

  def test_non_existent_form
    assert_raise WuParty::HTTPError do
      @wufoo.form('does-not-exist')
    end
  end

  def test_reports
    assert @wufoo.reports
  end

  def test_users
    assert @wufoo.users
  end

  def test_form_fields
    form = @wufoo.form(@form_id)
    field_names = form.fields.map { |f| f['Title'] }
    assert field_names.include?('Name'), 'Name field not found in #fields'
    assert field_names.include?('Address'), 'Address field not found in #fields'
  end

  def test_form_submit
    form = @wufoo.form(@form_id)
    result = form.submit('Field1' => 'Tim', 'Field2' => 'Morgan', 'Field3' => '4010 W. New Orleans', 'Field5' => 'Broken Arrow', 'Field6' => 'OK', 'Field7' => '74011')
    assert_equal 1, result['Success']
    assert result['EntryId']
    assert result['EntryLink']
  end

  def test_form_submit_error
    form = @wufoo.form(@form_id)
    # test a form error -- non-existent field
    result = form.submit('Field1' => 'Tim', 'Field2' => 'Morgan', 'Field100' => 'Foobar')
    assert_equal 0, result['Success']
    assert result['ErrorText']
    assert_equal [], result['FieldErrors']
    # test a field error -- nothing in a required field
    result = form.submit('Field2' => 'Morgan')
    assert_equal 0, result['Success']
    assert_equal 1, result['FieldErrors'].length
    error = result['FieldErrors'].first
    assert_equal 'Field1', error['ID']
    assert_match /required/i, error['ErrorText']
  end

  def test_entries
    form = @wufoo.form(@form_id)
    form.submit('Field1' => 'Tim', 'Field2' => 'Morgan')
    assert_equal 'Tim', form.entries.last['Field1']
  end

  def test_filtering_entries
    form = @wufoo.form(@form_id)
    form.submit('Field1' => 'Tim', 'Field2' => 'Morgan')
    id = form.submit('Field1' => 'Jane', 'Field2' => 'Smith')['EntryId']
    assert form.entries(:filters => [['Field2', 'Is_equal_to', 'Morgan']]).any?
    assert_equal 1, form.entries(:filters => [['EntryId', 'Is_equal_to', id]]).length
  end

  def test_add_webhook
    # test with optional parameters
    response = @wufoo.add_webhook(@form_id, "http://#{ENV['WUFOO_ACCOUNT']}.com/#{@form_id}", true, "handshakeKey01")
    assert_match /[a-z0-9]{6}/i, response['WebHookPutResult']['Hash']
    # test without optional parameters
    response = @wufoo.add_webhook(@form_id, "http://#{ENV['WUFOO_ACCOUNT']}.com/#{@form_id}-2")
    assert_match /[a-z0-9]{6}/i, response['WebHookPutResult']['Hash']
  end

end
