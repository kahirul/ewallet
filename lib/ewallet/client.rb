module Ewallet
  module Client
    extend self

    private

    def make_request(method, url, params, headers, auth_header = nil, www = false)
      method = method.to_s.upcase

      r_headers = {
        'Accept-Encoding' => 'None',
        'Authorization' => auth_header || default_auth_header,
        'Origin' => config.origin,
        'Content-Type' =>  www ? 'application/x-www-form-urlencoded' : 'application/json'
      }.merge(headers)

      conn = Faraday.new(url: url)

      if www
        conn.post do |req|
          req.headers = r_headers
          req.body = URI.encode_www_form(params) if params
        end
      else
        body = params && ActiveSupport::JSON.encode(params)

        conn.send(method.downcase.to_sym) do |req|
          req.headers = r_headers

          if body
            req.body = body if method == 'POST' || method == 'PUT'
            req.params = body if method == 'GET'
          end

        end
      end
    end
  end
end
