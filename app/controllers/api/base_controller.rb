module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session

    before_action :set_cors_headers
    before_action :authenticate_request!

    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordNotUnique, with: :render_conflict

    attr_reader :current_user, :current_user_session, :current_api_token

    private

    def authenticate_request!
      if controller_path.start_with?("api/v1/admin/")
        authenticate_user_session!(allowed_roles: %w[admin])
      elsif controller_path.start_with?("api/v1/professional_portal/")
        authenticate_user_session!(allowed_roles: %w[professional])
      elsif controller_path.start_with?("api/v1/integrations/")
        authenticate_integration_token!
      end
    end

    def authenticate_user_session!(allowed_roles: User::ROLES)
      session = UserSession.authenticate(bearer_token)

      unless session && allowed_roles.include?(session.user.role)
        render json: { error: "Não autorizado" }, status: :unauthorized
        return
      end

      session.mark_used!
      @current_user_session = session
      @current_user = session.user
    end

    def authenticate_integration_token!
      token = ApiToken.authenticate(bearer_token)

      unless token&.scope == "integration"
        render json: { error: "Não autorizado" }, status: :unauthorized
        return
      end

      token.mark_used!
      @current_api_token = token
    end

    def bearer_token
      request.authorization.to_s.delete_prefix("Bearer ").strip
    end

    def set_cors_headers
      origin = ENV["FRONTEND_ORIGIN"]
      origin = "*" if origin.blank? && !Rails.env.production?

      headers["Access-Control-Allow-Origin"] = origin if origin.present?
      headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
      headers["Access-Control-Allow-Methods"] = "GET, POST, PATCH, PUT, DELETE, OPTIONS"
    end

    def render_bad_request(exception)
      render json: { error: exception.message }, status: :bad_request
    end

    def render_not_found(_exception)
      render json: { error: "Recurso não encontrado" }, status: :not_found
    end

    def render_conflict(_exception)
      render json: { error: "Registro duplicado ou conflito de integridade" }, status: :unprocessable_entity
    end
  end
end
