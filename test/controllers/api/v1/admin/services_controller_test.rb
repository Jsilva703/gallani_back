require "test_helper"

class Api::V1::Admin::ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @service = services(:corte)
  end

  test "lists services ordered by name" do
    get api_v1_admin_services_url, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal ["Corte", "Pigmentação"], body.pluck("name")
  end

  test "filters services by query and active status" do
    get api_v1_admin_services_url, params: { query: "pigment", active: false }, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal 1, body.size
    assert_equal "Pigmentação", body.first["name"]
    assert_equal false, body.first["active"]
  end

  test "creates a service" do
    assert_difference("Service.count", 1) do
      post api_v1_admin_services_url,
           params: { service: { name: "Barba", description: "Modelagem", price: 30 } },
           as: :json
    end

    assert_response :created
    body = response.parsed_body
    assert_equal "Barba", body["name"]
    assert_equal 30.0, body["price"]
    assert_equal true, body["active"]
  end

  test "rejects an invalid service" do
    assert_no_difference("Service.count") do
      post api_v1_admin_services_url,
           params: { service: { name: "", description: "Inválido", price: 0 } },
           as: :json
    end

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].present?
  end

  test "updates a service" do
    patch api_v1_admin_service_url(@service),
          params: { service: { price: 50, active: false } },
          as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal 50.0, body["price"]
    assert_equal false, body["active"]
  end
end

