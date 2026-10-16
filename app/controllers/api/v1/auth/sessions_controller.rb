module Api
  module V1
    module Auth
      class SessionsController < Api::BaseController
        skip_before_action :authenticate_request!
        before_action :authenticate_session_user!, only: %i[show destroy]

        def create
          user = User.includes(:professional)
                     .find_by("LOWER(email) = ?", params.require(:email).to_s.strip.downcase)

          unless user&.access_allowed? && user.authenticate(params.require(:password))
            return render json: { error: "E-mail ou senha inválidos" }, status: :unauthorized
          end

          session, raw_token = UserSession.issue_for!(user)

          render json: {
            token: raw_token,
            expires_at: session.expires_at.iso8601,
            user: UserSerializer.new(user).as_json
          }, status: :created
        end

        def show
          render json: { user: UserSerializer.new(current_user).as_json }
        end

        def destroy
          current_user_session.destroy!
          head :no_content
        end

        private

        def authenticate_session_user!
          authenticate_user_session!(allowed_roles: User::ROLES)
        end
      end
    end
  end
end
