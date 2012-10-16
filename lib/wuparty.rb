require 'httparty'
gem 'multipart-post'
require 'net/http/post/multipart'
gem 'mime-types'
require 'mime/types'

# multipart POST support from David Balater's fork of HTTParty:
# http://github.com/dbalatero/httparty
# :stopdoc:
module HTTParty
  module ClassMethods
    def post(path, options={})
      klass = options[:multipart] ? Net::HTTP::Post::Multipart : Net::HTTP::Post
      perform_request klass, path, options
    end
  end
  class Request
    SupportedHTTPMethods << Net::HTTP::Post::Multipart
    private
      def setup_raw_request
        if multipart?
          @file_handles = []
          io_objects = {}

          options[:multipart].each do |field_name, info|
            fp = File.open(info[:path])
            @file_handles << fp

            io_objects[field_name] = UploadIO.new(fp,
                                                  info[:type],
                                                  info[:path])
          end

          if options[:body]
            options[:body].each do |field_name, value|
              io_objects[field_name] = value
            end
          end

          @raw_request = http_method.new(uri.request_uri,
                                         io_objects)

          # We have to duplicate and merge the headers set by the
          # multipart object to make sure that Net::HTTP 
          # doesn't override them down the line when it calls
          # initialize_http_header.
          #
          # Otherwise important headers like Content-Length,
          # Accept, and Content-Type will be deleted.
          original_headers = {}
          @raw_request.each do |key, value|
            original_headers[key] = value
          end

          options[:headers] ||= {}
          original_headers.merge!(options[:headers])
          options[:headers] = original_headers
        else
          @raw_request = http_method.new(uri.request_uri)
          @raw_request.body = body if body
        end

        @raw_request.initialize_http_header options[:headers]
        @raw_request.basic_auth(username, password) if options[:basic_auth]
      end
      def multipart?
        Net::HTTP::Post::Multipart == http_method
      end
  end
end
# :startdoc:

class WuParty
  include HTTParty
  format :json

  VERSION = '1.0.2'

  # Represents a general error connecting to the Wufoo service
  class ConnectionError < RuntimeError; end

  # Represents a specific error returned from Wufoo.
  class HTTPError < RuntimeError
    def initialize(code, message) # :nodoc:
      @code = code
      super(message)
    end

    # Error code
    attr_reader :code
  end

  ENDPOINT    = 'https://%s.wufoo.com/api/v3'
  API_VERSION = '3.0'

  # uses the Login API to fetch a user's API key
  def self.login(integration_key, email, password, account = nil)
    result = self.post("https://wufoo.com/api/v3/login.json", { :body => { :integrationKey => integration_key, :email => email, :password => password, :subdomain => account }})
    if result.is_a?(String)
      raise ConnectionError, result
    elsif result['HTTPCode']
      raise HTTPError.new(result['HTTPCode'], result['Text'])
    else
      result
    end
  end

  # Create a new WuParty object
  def initialize(account, api_key)
    @account = account
    @api_key = api_key
    @field_numbers = {}
  end

  # Returns list of forms and details accessible by the user account.
  def forms
    get(:forms)['Forms'].map do |details|
      Form.new(details['Url'], :party => self, :details => details)
    end
  end

  # Returns list of reports and details accessible by the user account.
  def reports
    get(:reports)['Reports'].map do |details|
      Report.new(details['Url'], :party => self, :details => details)
    end
  end

  # Returns list of users and details.
  def users
    get(:users)['Users'].map do |details|
      User.new(details['Url'], :party => self, :details => details)
    end
  end

  # Returns details about the specified form.
  def form(form_id)
    if f = get("forms/#{form_id}")['Forms']
      Form.new(f.first['Url'], :party => self, :details => f.first)
    end
  end

  def add_webhook(form_id, url, metadata = false, handshakeKey = "")
    put("forms/#{form_id}/webhooks", :body => {'url' => url, 'handshakeKey' => handshakeKey, 'metadata' => metadata})
  end

  def delete_webhook(form_id, webhook_hash)
    delete("forms/#{form_id}/webhooks/#{webhook_hash}")
  end

  # Returns details about the specified report.
  def report(report_id)
    if r = get("reports/#{report_id}")['Reports']
      Report.new(r.first['Url'], :party => self, :details => r.first)
    end
  end

  def get(method, options={}) # :nodoc:
    handle_http_verb(:get, method, options)
  end

  def post(method, options={}) # :nodoc:
    handle_http_verb(:post, method, options)
  end

  def put(method, options={}) # :nodoc:
    handle_http_verb(:put, method, options)
  end

  def delete(method, options={}) # :nodoc:
    handle_http_verb(:delete, method, options)
  end

  private

    def base_url
      ENDPOINT % @account
    end

    def handle_http_verb(verb, action, options={})
      options.merge!(:basic_auth => {:username => @api_key})
      url = "#{base_url}/#{action}.json"
      result = self.class.send(verb, url, options)
      if result.is_a?(String)
        raise ConnectionError, result
      elsif result['HTTPCode']
        raise HTTPError.new(result['HTTPCode'], result['Text'])
      else
        result
      end
    end

  public

  # ----------

  class Entity # :nodoc:
    include HTTParty
    format :json

    def initialize(id, options)
      @id = id
      if options[:party]
        @party = options[:party]
      elsif options[:account] and options[:api_key]
        @party = WuParty.new(options[:account], options[:api_key])
      else
        raise WuParty::InitializationException, "You must either specify a :party object or pass the :account and :api_key options. Please see the README."
      end
      @details = options[:details]
    end

    attr_reader :id
    attr_accessor :details
  end

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

    def add_webhook(url, metadata = false, handshakeKey = "")
      @party.add_webhook(@details["Hash"], url, metadata, handshakeKey)
    end

    def delete_webhook(webhook_id)
      @party.delete_webhook(@details["Hash"], webhook_id)
    end

    # Returns fields and subfields, as a flattened array, e.g.
    #   [{'ID' => 'Field1', 'Title' => 'Name - First', 'Type' => 'shortname', 'Required' => true }, # (subfield)
    #    {'ID' => 'Field2', 'Title' => 'Name - Last',  'Type' => 'shortname', 'Required' => true }, # (subfield)
    #    {'ID' => 'Field3', 'Title' => 'Birthday',     'Type' => 'date',      'Required' => flase}] # (field)
    # By default, only fields that can be submitted are returned. Pass *true* as the first arg to return all fields.
    def flattened_fields(all=false)
      flattened = []
      fields.each do |field|
        next unless all or field['ID'] =~ /^Field/
        if field['SubFields']
          field['SubFields'].each do |sub_field|
            flattened << {'ID' => sub_field['ID'], 'Title' => field['Title'] + ' - ' + sub_field['Label'], 'Type' => field['Type'], 'Required' => field['IsRequired'] == '1'}
          end
        else
          flattened << {'ID' => field['ID'], 'Title' => field['Title'], 'Type' => field['Type'], 'Required' => field['IsRequired'] == '1'}
        end
      end
      flattened
    end

    # Return entries already submitted to the form.
    #
    # Supports:
    #   - filtering:
    #   entries(:filters => [['Field1', 'Is_equal_to', 'Tim']])
    #   entries(:filters => [['Field1', 'Is_equal_to', 'Tim'], ['Field2', 'Is_equal_to', 'Morgan']], :filter_match => 'OR')
    #
    #   - sorting:
    #   entries(:sort => 'EntryId DESC')
    #
    #   - limiting:
    #   entries(:limit => 5)
    #
    # See http://wufoo.com/docs/api/v3/entries/get/#filter for details
    def entries(options={})
      query = {}

      if options[:filters]
        query['match'] = options[:filter_match] || 'AND'
        options[:filters].each_with_index do |filter, index|
          query["Filter#{ index + 1 }"] = filter.join(' ')
        end
      end

      if options[:limit]
        query[:pageSize] = options[:limit]
        query[:pageStart] = 0
      end

      if options[:sort]
        field, direction = options[:sort].split(' ')
        query[:sort] = field
        query[:sortDirection] = direction || 'ASC'
      end

      @party.get("forms/#{@id}/entries", :query => query)['Entries']
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
          options[:multipart][key] = {:type => type, :path => value[:path]}
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
    def comments(options={})
      options = {:query => options} if options.any?
      @party.get("forms/#{@id}/comments", options)['Comments']
    end
  end

  # Wraps an individual Wufoo Report.
  # == Instantiation
  # There are two ways to instantiate a Report object:
  # 1. Via the parent WuParty object that represents the account.
  # 2. Via the WuParty::Report class directly.
  #   wufoo = WuParty.new(ACCOUNT, API_KEY)
  #   report = wufoo.report(REPORT_ID)
  #   # or...
  #   report = WuParty::Report.new(REPORT_ID, :account => ACCOUNT, :api_key => API_KEY)
  # The first technique makes a call to the Wufoo API to get the report details,
  # while the second technique lazily loads the report details, once something is accessed via [].
  # == \Report Details
  # Access report details like it is a Hash, e.g.:
  #   report['Name']
  class Report < Entity
    # Access report details.
    def [](id)
      @details ||= @party.report(@id)
      @details[id]
    end

    # Returns field details for the report
    def fields
      @party.get("reports/#{@id}/fields")['Fields']
    end

    # Returns widget details for the report
    def widgets
      @party.get("reports/#{@id}/widgets")['Widgets']
    end
  end

  # Wraps an individual Wufoo User.
  class User < Entity

    # Access user details.
    def [](id)
      @details ||= @party.report(@id)
      @details[id]
    end

  end
end
