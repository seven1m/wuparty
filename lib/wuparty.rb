# frozen_string_literal: true

require 'httparty'

require_relative './wuparty/entity'
require_relative './wuparty/form'
require_relative './wuparty/report'
require_relative './wuparty/user'
require_relative './wuparty/version'

class WuParty
  include HTTParty
  format :json

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

  API_VERSION = '3.0'

  # uses the Login API to fetch a user's API key
  def self.login(integration_key, email, password, account = nil)
    result = post(
      'https://wufoo.com/api/v3/login.json',
      body: {
        integrationKey: integration_key,
        email:          email,
        password:       password,
        subdomain:      account
      }
    )
    raise ConnectionError, result if result.is_a?(String)
    raise HTTPError.new(result['HTTPCode'], result['Text']) if result['HTTPCode']
    result
  end

  # Create a new WuParty object
  def initialize(account, api_key, domain: 'wufoo.com', account_prefix: nil)
    @account = account
    @api_key = api_key
    @domain = domain
    @account_prefix = account_prefix || @account
    @field_numbers = {}
  end

  # Returns list of forms and details accessible by the user account.
  def forms
    get(:forms)['Forms'].map do |details|
      Form.new(details['Url'], party: self, details: details)
    end
  end

  # Returns list of reports and details accessible by the user account.
  def reports
    get(:reports)['Reports'].map do |details|
      Report.new(details['Url'], party: self, details: details)
    end
  end

  # Returns list of users and details.
  def users
    get(:users)['Users'].map do |details|
      User.new(details['Url'], party: self, details: details)
    end
  end

  # Returns details about the specified form.
  def form(form_id)
    return unless (f = get("forms/#{form_id}")['Forms'])
    Form.new(f.first['Url'], party: self, details: f.first)
  end

  def add_webhook(form_id, url, metadata = false, handshake_key = '')
    put(
      "forms/#{form_id}/webhooks",
      body: {
        'url' => url,
        'handshakeKey' => handshake_key,
        'metadata' => metadata
      }
    )
  end

  def delete_webhook(form_id, webhook_hash)
    delete("forms/#{form_id}/webhooks/#{webhook_hash}")
  end

  # Returns details about the specified report.
  def report(report_id)
    return unless (r = get("reports/#{report_id}")['Reports'])
    Report.new(r.first['Url'], party: self, details: r.first)
  end

  def get(method, options = {}) # :nodoc:
    handle_http_verb(:get, method, options)
  end

  def post(method, options = {}) # :nodoc:
    handle_http_verb(:post, method, options)
  end

  def put(method, options = {}) # :nodoc:
    handle_http_verb(:put, method, options)
  end

  def delete(method, options = {}) # :nodoc:
    handle_http_verb(:delete, method, options)
  end

  private

  def base_url
    "https://#{@account_prefix}.#{@domain}/api/v3"
  end

  def handle_http_verb(verb, action, options = {})
    options[:basic_auth] = { username: @api_key }
    url = "#{base_url}/#{action}.json"
    result = self.class.send(verb, url, options)
    begin
      result.to_s # trigger parse error if possible
    rescue MultiJson::DecodeError => e
      raise HTTPError.new(500, e.message)
    end
    raise ConnectionError, result if result.is_a?(String)
    raise HTTPError.new(result['HTTPCode'], result['Text']) if result['HTTPCode']
    result
  end
end
