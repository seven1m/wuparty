require 'httparty'

class WufooParty
  include HTTParty
  format :json

  ENDPOINT    = 'http://%s.wufoo.com/api/v3'
  API_VERSION = '3.0'

  # Create a new WufooParty object
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

  # Returns details about the specified report.
  def report(report_id)
    if r = get("reports/#{report_id}")['Reports']
      Form.new(r.first['Url'], :party => self, :details => r.first)
    end
  end

  def get(method, options={}) # :nodoc:
    options.merge!(:basic_auth => {:username => @api_key})
    url = "#{base_url}/#{method}.json"
    self.class.get(url, options)
  end

  def post(method, options={}) # :nodoc:
    options.merge!(:basic_auth => {:username => @api_key})
    url = "#{base_url}/#{method}.json"
    self.class.post(url, options)
  end

  private

    def base_url
      ENDPOINT % @account
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
        @party = WufooParty.new(options[:account], options[:api_key])
      else
        raise WufooParty::InitializationException, "You must either specify a :party object or pass the :account and :api_key options. Please see the README."
      end
      @details = options[:details]
    end

    attr_accessor :details

    # Return details
    def [](id)
      @details ||= @party.form(@id)
      @details[id]
    end
  end

  class Form < Entity
    # Returns field details for the form.
    def fields
      @party.get("forms/#{@id}/fields")['Fields']
    end

    # Return entries already submitted to the form
    # If you need to filter entries, pass an array as the first argument:
    #   entries([[field_id, operator, value], ...])
    # e.g.:
    #   entries([['EntryId', 'Is_after', 12], ['EntryId', 'Is_before', 17]])
    #   entries([['Field1', 'Is_equal', 'Tim']])
    # The second arg is the match parameter (AND/OR) and defaults to 'AND', e.g.
    #   entries([['Field2', 'Is_equal', 'Morgan'], ['Field2', 'Is_equal', 'Smith']], 'OR')
    # See http://wufoo.com/docs/api/v3/entries/get/#filter for details
    def entries(filters=[], filter_match='AND')
      if filters.any?
        options = {'match' => filter_match}
        filters.each_with_index do |filter, index|
          options["Filter#{index+1}"] = filter.join(' ')
        end
        options = {:query => options}
      else
        options = {}
      end
      @party.get("forms/#{@id}/entries", options)['Entries']
    end

    # Submit form data to the form.
    # Pass data as a hash, with field ids as the hash keys, e.g.
    #   submit('Field1' => 'Tim', 'Field2' => 'Morgan')
    # Return value includes the following keys:
    # * Status
    # * ErrorText
    # * FieldErrors
    def submit(data)
      @party.post("forms/#{@id}/entries", :body => data)
    end

    # Returns comment details for the form.
    # See Wufoo API documentation for possible options, e.g.
    # you can specify 'entryId' => 123 to filter comments only for the specified entry.
    def comments(options={})
      options = {:query => options} if options.any?
      @party.get("forms/#{@id}/comments", options)['Comments']
    end
  end

  class Report < Entity
    # Returns field details for the report
    def fields
      @party.get("reports/#{@id}/fields")['Fields']
    end

    # Returns widget details for the report
    def widgets
      @party.get("reports/#{@id}/widgets")['Widgets']
    end
  end

  class User < Entity

  end
end
