require "test_helper"
require "securerandom"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @password = SecureRandom.hex(16)
    @admin = User.create!(
      name: "Admin",
      email: "admin@example.com",
      password: @password,
      password_confirmation: @password,
      role: "admin"
    )
  end

  test "login me e logout" do
    post "/api/v1/auth/login",
         params: {
           email: "ADMIN@example.com",
           password: @password
         }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :created

    token = JSON.parse(response.body).fetch("token")

    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal @admin.id, JSON.parse(response.body).dig("user", "id")

    delete "/api/v1/auth/logout",
           headers: { "Authorization" => "Bearer #{token}" }

    assert_response :no_content

    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unauthorized
  end

  test "senha inválida não cria sessão" do
    assert_no_difference("UserSession.count") do
      post "/api/v1/auth/login",
           params: {
             email: @admin.email,
             password: SecureRandom.hex(16)
           }.to_json,
           headers: { "Content-Type" => "application/json" }
    end

    assert_response :unauthorized
  end

  test "usuário inativo não autentica" do
    @admin.update!(active: false)

    post "/api/v1/auth/login",
         params: {
           email: @admin.email,
           password: @password
         }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
  end
end
