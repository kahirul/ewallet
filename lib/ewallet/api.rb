module Ewallet
  module Api
    extend self

    attr_reader :client_access_token

    def register_user(user, client_access_token = nil)
      @client_access_token = client_access_token

      return if user.customer_number.present?

      url       = config.base_url + '/ewallet/customers'
      method    = 'POST'
      timestamp = Time.current.strftime('%Y-%m-%dT%H:%M:%S.%L%z')

      customer_number = user.id.to_s

      body = {
        'CustomerName' => user.full_name,
        'DateOfBirth' => '1990-08-08',
        'PrimaryID' => user.ewallet_id,
        'MobileNumber' => (user.phone.presence || '+62888' + user.id.to_s),
        'EmailAddress' => user.email,
        'CompanyCode' => config.company_code,
        'CustomerNumber' => customer_number
      }

      headers = {
        hd_bca_key => config.api_key,
        hd_bca_timestamp => timestamp,
        hd_bca_signature => signature(method, url, body, timestamp)
      }

      response = make_request(method, url, body, headers, auth_header)
      if response.success?
        user.update(customer_number: customer_number)
      end
      return response
    end

    def inquiry_user(user, client_access_token = nil)
      @client_access_token = client_access_token

      url       = config.base_url + "/ewallet/customers/#{config.company_code}/#{user.ewallet_id}"
      method    = 'GET'
      timestamp = Time.current.strftime('%Y-%m-%dT%H:%M:%S.%L%z')

      headers = {
        hd_bca_key => config.api_key,
        hd_bca_timestamp => timestamp,
        hd_bca_signature => signature(method, url, nil, timestamp)
      }

      make_request(method, url, nil, headers, auth_header)
    end

    def update_user(user, active = true)
      url       = config.base_url + "/ewallet/customers/#{config.company_code}/#{user.ewallet_id}"
      method    = 'PUT'
      timestamp = Time.current.strftime('%Y-%m-%dT%H:%M:%S.%L%z')

      body = {
        'CustomerName' => user.full_name,
        'DateOfBirth' => (user.birthday || '1980-08-08').to_s,
        'MobileNumber' => user.phone,
        'EmailAddress' => user.email,
        'WalletStatus' => active ? 'ACTIVE' : 'BLOCKED'
      }

      headers = {
        'X-BCA-Key' => config.api_key,
        'X-BCA-Timestamp' => timestamp,
        'X-BCA-Signature' => signature(method, url, body, timestamp)
      }

      make_request(method, url, body, headers, auth_header)
    end

    def charge(payment, client_access_token = nil)
      @client_access_token = client_access_token

      order     = payment.order
      user      = order.user
      url       = config.base_url + '/ewallet/payments'
      method    = 'POST'
      timestamp = Time.current.strftime('%Y-%m-%dT%H:%M:%S.%L%z')

      charge = WalletCharge.new(
        user: user,
        transaction_id: order.number,
        reference_id: Time.current.to_i.to_s,
        request_date: timestamp,
        amount: payment.amount,
        currency: order.currency
      )

      body = {
        'CompanyCode' => config.company_code,
        'PrimaryID' => user.ewallet_id,
        'TransactionID' => charge.transaction_id,
        'ReferenceID' => charge.reference_id,
        'RequestDate' => charge.request_date,
        'Amount' => format('%.2f', charge.amount),
        'CurrencyCode' => charge.currency
      }

      headers = {
        'X-BCA-Key' => config.api_key,
        'X-BCA-Timestamp' => timestamp,
        'X-BCA-Signature' => signature(method, url, body, timestamp)
      }

      response = make_request(method, url, body, headers, auth_header)
      if response.success?
        data = ActiveSupport::JSON.decode(response.body).with_indifferent_access
        charge.payment_id = data[:PaymentID]
        charge.save
      end

      return response
    end

    def payment_status(user, charge, client_access_token = nil)
      @client_access_token = client_access_token

      timestamp = Time.current.strftime('%Y-%m-%dT%H:%M:%S.%L%:z')
      url       = config.base_url + "/ewallet/payments/#{config.company_code}/#{user.ewallet_id}?ReferenceID=#{charge.reference_id}&RequestDate=#{charge.request_date.to_date}&TransactionID=#{charge.transaction_id}"
      method    = 'GET'

      headers = {
        'X-BCA-Key' => config.api_key,
        'X-BCA-Timestamp' => timestamp,
        'X-BCA-Signature' => signature(method, url, nil, timestamp)
      }

      return make_request(method, url, nil, headers, auth_header)
    end

    def topup(user, amount, currency = 'IDR', client_access_token = nil)
      @client_access_token = client_access_token

      url       = config.base_url + '/ewallet/topup'
      method    = 'POST'
      timestamp = Time.current.strftime('%Y-%m-%dT%H:%M:%S.%L%:z')

      topup = EwalletTopup.new(
        user: user,
        transaction_id: 'TRX' + Time.current.to_i.to_s,
        amount: amount,
        currency_code: currency
      )

      body = {
        'CompanyCode' => config.company_code,
        'CustomerNumber' => user.customer_number,
        'TransactionID' => topup.transaction_id,
        'RequestDate' => timestamp,
        'Amount' => format('%.2f', topup.amount),
        'CurrencyCode' => currency
      }

      headers = {
        'X-BCA-Key' => config.api_key,
        'X-BCA-Timestamp' => timestamp,
        'X-BCA-Signature' => signature(method, url, body, timestamp)
      }

      response = make_request(method, url, body, headers, auth_header)
      if response.success?
        data = ActiveSupport::JSON.decode(response.body).with_indifferent_access
        topup.topup_id = data[:TopUpID]
        topup.save
      end
      return response
    end

    def transaction_history(user, start_date, end_date, last_statement_id = '', client_access_token = nil)
      @client_access_token = client_access_token

      url       = config.base_url + "/ewallet/transactions/#{config.company_code}/#{user.ewallet_id}?EndDate=#{end_date}&LastAccountStatementID=#{last_statement_id}&StartDate=#{start_date}"
      timestamp = Time.current.strftime('%Y-%m-%dT%H:%M:%S.%L%:z')
      method    = 'GET'

      headers = {
        'X-BCA-Key' => config.api_key,
        'X-BCA-Timestamp' => timestamp,
        'X-BCA-Signature' => signature(method, url, nil, timestamp)
      }

      return make_request(method, url, nil, headers, auth_header)
    end

    def oauth_token
      client_access_token || server_access_token
    end

    def server_access_token
      @server_access_token ||= begin
        url       = config.base_url + '/api/oauth/token'
        method    = 'POST'

        body = {
          'grant_type' => 'client_credentials'
        }

        auth_pair = Base64.strict_encode64(config.client_id + ':' + config.client_secret)
        _auth_header = "Basic #{auth_pair}"

        response = make_request(method, url, body, {}, _auth_header, true)

        response.success? && ActiveSupport::JSON.decode(response.body).with_indifferent_access[:access_token]
      end
    end

    def auth_header
      "Bearer #{oauth_token}"
    end

    def hd_bca_key
      CaseSensitiveString.new('X-BCA-Key')
    end

    def hd_bca_timestamp
      CaseSensitiveString.new('X-BCA-Timestamp')
    end

    def hd_bca_signature
      CaseSensitiveString.new('X-BCA-Signature')
    end

    def signature(method, url, body, timestamp)
      uri = URI.parse(url)

      relative_url  = [uri.path, uri.query].compact.join('?')
      clean_body    = body && ActiveSupport::JSON.encode(body).gsub(/\s+/, '') || ''
      req_body      = Digest::SHA256.hexdigest(clean_body).downcase

      payload = [method, relative_url, oauth_token, req_body, timestamp.to_s].join(':')

      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha256'), config.api_secret, payload)
    end

  end
end
