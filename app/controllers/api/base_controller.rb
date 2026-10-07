# app/controllers/api/base_controller.rb
module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session
  end
end