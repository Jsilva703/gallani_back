module Api
  module V1
    module Admin
      class UsersController < Api::BaseController
        def index
          users = User.includes(:professional).order(:name)
          users = users.where(role: params[:role]) if params[:role].present?
          users = users.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params.key?(:active)

          render json: { data: users.map { |user| UserSerializer.new(user).as_json } }
        end

        def create
          user = User.new(create_params)

          if user.save
            render json: { data: UserSerializer.new(user).as_json }, status: :created
          else
            render json: { errors: user.errors }, status: :unprocessable_entity
          end
        end

        def update
          user = User.find(params[:id])
          attributes = update_params.to_h

          return render_self_lockout_error if self_lockout?(user, attributes)

          password_changed = attributes["password"].present?
          deactivating = attributes.key?("active") &&
                         !ActiveModel::Type::Boolean.new.cast(attributes["active"])

          attributes.delete("password") if attributes["password"].blank?
          attributes.delete("password_confirmation") if attributes["password_confirmation"].blank?

          if user.update(attributes)
            user.user_sessions.delete_all if password_changed || deactivating
            render json: { data: UserSerializer.new(user).as_json }
          else
            render json: { errors: user.errors }, status: :unprocessable_entity
          end
        end

        private

        def create_params
          params.require(:user).permit(
            :name, :email, :password, :password_confirmation, :role, :professional_id
          )
        end

        def update_params
          params.require(:user).permit(
            :name, :email, :password, :password_confirmation, :role, :professional_id, :active
          )
        end

        def self_lockout?(user, attributes)
          return false unless user.id == current_user.id

          deactivating = attributes.key?("active") &&
                         !ActiveModel::Type::Boolean.new.cast(attributes["active"])
          removing_admin_role = attributes.key?("role") && attributes["role"] != "admin"

          deactivating || removing_admin_role
        end

        def render_self_lockout_error
          render json: {
            errors: {
              user: ["não é possível desativar ou remover o próprio acesso administrativo"]
            }
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
