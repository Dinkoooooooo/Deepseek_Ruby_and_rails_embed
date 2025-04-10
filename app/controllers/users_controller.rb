class UsersController < ApplicationController
    before_action :authenticate_user!
  
    def heidi_widget
      @user = User.find(params[:id])
      return unauthorized_response unless @user == current_user
  
      heidi_token = @user.heidi_token
      buffer_time = 5.minutes
  
      if heidi_token&.expires_at&.future?(buffer_time)
        @heidi_token = heidi_token.jwt
      else
        fetch_and_store_heidi_token(heidi_token)
      end
  
      respond_to do |format|
        format.js   # Render JS response for AJAX
        format.html # Optional fallback for HTML
      end
    rescue StandardError => e
      Rails.logger.error "Heidi Widget Error: #{e.message}"
      render json: { error: 'Failed to load Heidi widget' }, status: :unprocessable_entity
    end
  
    private
  
    def unauthorized_response
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  
    def fetch_and_store_heidi_token(heidi_token)
      service = HeidiJwtService.new(@user)
      jwt_data = service.fetch_jwt
      HeidiToken.transaction do
        heidi_token ||= @user.build_heidi_token
        heidi_token.update!(jwt: jwt_data[:jwt], expires_at: jwt_data[:expires_at])
      end
      @heidi_token = jwt_data[:jwt]
    rescue StandardError => e
      raise StandardError, "Failed to fetch or store Heidi token: #{e.message}"
    end
  end
  