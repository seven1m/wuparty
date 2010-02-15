require 'httparty'

class WufooParty
  include HTTParty
  format :json
  
  QUERY_ENDPOINT = 'http://%s.wufoo.com/api/query/'
  SUBMIT_ENDPOINT = 'http://%s.wufoo.com/api/insert/'
  API_VERSION = '2.0'
  
  # Create a new WufooParty object
  def initialize(account, api_key)
    @account = account
    @api_key = api_key
    @field_numbers = {}
  end
  
  # Perform a query on a specific form_id.
  # Returns details about the form, as well as individual form submission details.
  def query(form_id)
    args = {
      'w_api_key' => @api_key,
      'w_version' => API_VERSION,
      'w_form'    => form_id
    }
    result = self.class.post(QUERY_ENDPOINT % @account, :body => args)
    add_title_to_fields!(result)
    result
  end
  
  # Perform a submission to a specific form_id.
  # Returns status of operation.
  def submit(form_id, data={})
    args = {
      'w_api_key' => @api_key,
      'w_form'    => form_id
    }.merge(data)
    self.class.post(SUBMIT_ENDPOINT % @account, :body => args)
  end
  
  # Queries a form to get its field details
  def field_details(form_id)
    query(form_id)['form']['Fields']
  end
  
  # Queries a form to get its field numbers and names and types
  def field_numbers_and_names_and_types(form_id)
    get_field_numbers(field_details(form_id))
  end
  
  # Converts an array of field specs (returned by Wufoo) into a simple hash of <tt>{FIELDNUM => [FIELDNAME, FIELDTYPE]}</tt>
  def get_field_numbers(field_data, is_sub_fields=false, typeof=nil)
    field_data.inject({}) do |hash, field|
      if field['SubFields']
        hash.merge!(get_field_numbers(field['SubFields'], :is_sub_fields, field['Typeof']))
      elsif field['ColumnId'] =~ /^\d+$/
        title = is_sub_fields && field['ChoicesText'] ? field['ChoicesText'] : field['Title']
        hash[field['ColumnId']] = [title, field['Typeof'] || typeof]
      end
      hash
    end
  end
  
  # Given the result of a query, adds a 'Pretty' key to each form entry
  # that includes the field titles.
  def add_title_to_fields!(query_result)
    if query_result['form'] and query_result['form']['Entries']
      nums = get_field_numbers(query_result['form']['Fields'])
      query_result['form']['Entries'].each do |entry|
        entry['Pretty'] = {}
        entry.keys.each do |key|
          if key =~ /^Field(\d+)$/ and title = nums[$1]
            entry['Pretty'][title] = entry[key]
          end
        end
      end
    end
  end
end