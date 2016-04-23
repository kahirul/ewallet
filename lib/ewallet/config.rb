module Ewallet
  module Config
    extend self

    attr_reader :base_url, :company_code, :client_id, :client_secret
    attr_reader :api_key, :api_secret, :origin, :access_token

    @base_url = 'https://api.finhacks.id'

    def base_url=(value)
      @base_url = value
    end

    def company_code=(value)
      @company_code = value
    end

    def client_id=(value)
      @client_id = value
    end

    def client_secret=(value)
      @client_secret = value
    end

    def api_key=(value)
      @api_key = value
    end

    def api_secret=(value)
      @api_secret = value
    end

    def origin=(value)
      @origin = value
    end

  end
end
