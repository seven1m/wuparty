class WuParty
  # Wraps an individual Wufoo Form.
  # == Instantiation
  # There are two ways to instantiate a Form object:
  # 1. Via the parent WuParty object that represents the account.
  # 2. Via the WuParty::Form class directly.
  #   wufoo = WuParty.new(ACCOUNT, API_KEY)
  #   form = wufoo.form(FORM_ID)
  #   # or...
  #   form = WuParty::Form.new(FORM_ID, :account => ACCOUNT, :api_key => API_KEY)
  # The first technique makes a call to the Wufoo API to get the form details,
  # while the second technique lazily loads the form details, once something is accessed via [].
  # == \Form Details
  # Access form details like it is a Hash, e.g.:
  #   form['Name']
  #   form['RedirectMessage']
  class Form < Entity
    # Returns field details for the form.
    def fields
      @party.get("forms/#{@id}/fields")['Fields']
    end

    # Access form details.
    def [](id)
      @details ||= @party.form(@id)
      @details[id]
    end

    def add_webhook(url, metadata = false, handshake_key = '')
      @party.add_webhook(@details['Hash'], url, metadata, handshake_key)
    end

    def delete_webhook(webhook_id)
      @party.delete_webhook(@details['Hash'], webhook_id)
    end

    # Returns fields and subfields, as a flattened array, e.g.
    #   [{'ID' => 'Field1', 'Title' => 'Name - First', 'Type' => 'shortname', 'Required' => true }, # (subfield)
    #    {'ID' => 'Field2', 'Title' => 'Name - Last',  'Type' => 'shortname', 'Required' => true }, # (subfield)
    #    {'ID' => 'Field3', 'Title' => 'Birthday',     'Type' => 'date',      'Required' => flase}] # (field)
    # By default, only fields that can be submitted are returned. Pass *true* as the first arg to return all fields.
    def flattened_fields(all = false)
      flattened = []
      fields.each do |field|
        next unless all || field['ID'] =~ /^Field/
        if field['SubFields']
          field['SubFields'].each do |sub_field|
            flattened << {
              'ID' => sub_field['ID'],
              'Title' => field['Title'] + ' - ' + sub_field['Label'],
              'Type' => field['Type'],
              'Required' => field['IsRequired'] == '1'
            }
          end
        else
          flattened << {
            'ID' => field['ID'],
            'Title' => field['Title'],
            'Type' => field['Type'],
            'Required' => field['IsRequired'] == '1'
          }
        end
      end
      flattened
    end

    # Return entries already submitted to the form.
    #
    # Supports:
    #   - filtering:
    #   entries(filters: [['Field1', 'Is_equal_to', 'Tim']])
    #   entries(filters: [['Field1', 'Is_equal_to', 'Tim'], ['Field2', 'Is_equal_to', 'Morgan']], filter_match: 'OR')
    #
    #   - sorting:
    #   entries(sort: 'EntryId DESC')
    #
    #   - limiting:
    #   entries(limit: 5)
    #
    # See http://wufoo.com/docs/api/v3/entries/get/#filter for details
    def entries(options = {})
      query = {}

      if options[:filters]
        query['match'] = options[:filter_match] || 'AND'
        options[:filters].each_with_index do |filter, index|
          query["Filter#{index + 1}"] = filter.join(' ')
        end
      end

      query[:pageSize] = options[:limit] if options[:limit]

      query[:pageStart] = options[:pageStart] if options[:pageStart]

      query[:system] = true if options[:system]

      if options[:sort]
        field, direction = options[:sort].split(' ')
        query[:sort] = field
        query[:sortDirection] = direction || 'ASC'
      end

      @party.get("forms/#{@id}/entries", query: query)['Entries']
    end

    # Return entries already submitted to the form.
    #
    # Supports:
    # Same as Entries above with filtering.
    # form.count(:filters => [['Field1', 'Is_equal_to', 'Tim']])
    #
    # See http://wufoo.com/docs/api/v3/entries/get/#filter for details
    def count(options = {})
      query = {}

      if options[:filters]
        query['match'] = options[:filter_match] || 'AND'
        options[:filters].each_with_index do |filter, index|
          query["Filter#{index + 1}"] = filter.join(' ')
        end
      end

      query[:system] = true if options[:system]

      @party.get("forms/#{@id}/entries/count", query: query)['EntryCount']
    end

    # Submit form data to the form.
    # Pass data as a hash, with field ids as the hash keys, e.g.
    #   submit('Field1' => 'Tim', 'Field2' => 'Morgan')
    # Return value is a Hash that includes the following keys:
    # * Status
    # * ErrorText
    # * FieldErrors
    # You must submit values for required fields (including all sub fields),
    # and dates must be formatted as <tt>YYYYMMDD</tt>.
    def submit(data)
      options = {}
      data.each do |key, value|
        if value.is_a?(Hash)
          type = MIME::Types.of(value[:path]).first.content_type rescue 'application/octet-stream'
          options[:multipart] ||= {}
          options[:multipart][key] = { type: type, path: value[:path] }
        else
          options[:body] ||= {}
          options[:body][key] = value
        end
      end
      @party.post("forms/#{@id}/entries", options)
    end

    # Returns comment details for the form.
    # See Wufoo API documentation for possible options,
    # e.g. to filter comments for a specific form entry:
    #   form.comments('entryId' => 123)
    def comments(options = {})
      options = { query: options } if options.any?
      @party.get("forms/#{@id}/comments", options)['Comments']
    end
  end
end
