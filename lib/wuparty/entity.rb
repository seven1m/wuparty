class WuParty
  class Entity # :nodoc:
    include HTTParty
    format :json

    def initialize(id, options)
      @id = id
      if options[:party]
        @party = options[:party]
      elsif options[:account] && options[:api_key]
        @party = WuParty.new(options[:account], options[:api_key])
      else
        raise WuParty::InitializationException,
              'You must either specify a :party object or pass the :account and :api_key options. ' \
              'Please see the README.'
      end
      @details = options[:details]
    end

    attr_reader :id
    attr_accessor :details
  end
end
