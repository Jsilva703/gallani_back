require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "is valid with the frontend contract fields" do
    service = Service.new(name: "Barba", description: "Modelagem", price: 30, active: true)

    assert service.valid?
  end

  test "requires a name" do
    service = Service.new(description: "Modelagem", price: 30)

    assert_not service.valid?
    assert_includes service.errors[:name], "can't be blank"
  end

  test "requires a positive price" do
    service = Service.new(name: "Barba", price: 0)

    assert_not service.valid?
    assert_includes service.errors[:price], "must be greater than 0"
  end

  test "is active by default" do
    service = Service.create!(name: "Barba", price: 30)

    assert service.active?
  end
end

