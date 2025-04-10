# app/services/heidi_jwt_service.rb
class HeidiJwtService
    HEIDI_JWT_URL = 'https://registrar.api.heidihealth.com/api/v2/ml-scribe/open-api/jwt'.freeze
  
    def initialize(user)
      @user = user
    end
  
    def fetch_jwt
      response = connection.get do |req|
        req.params['email'] = @user.email
        req.params['third_party_internal_id'] = @user.id
        req.headers['Heidi-Api-Key'] = ENV['HEIDI_API_KEY']
      end
  
      if response.success?
        data = JSON.parse(response.body)
        {
          jwt: data['token'],
          expires_at: parse_expiration_time(data['expiration_time'])
        }
      else
        Rails.logger.error "Failed to fetch JWT: #{response.status}"
        raise StandardError, "Failed to fetch JWT"
      end
    rescue Faraday::Error => e
      Rails.logger.error "Faraday error: #{e.message}"
      raise
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing error: #{e.message}"
      raise
    end
  
    private
  
    def connection
      Faraday.new(url: HEIDI_JWT_URL) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger if Rails.env.development?
        faraday.adapter Faraday.default_adapter
      end
    end
  
    def parse_expiration_time(expiration_time_str)
      utc_time = Time.iso8601(expiration_time_str)
      utc_time.in_time_zone(Rails.application.config.time_zone)
    end
  end
  