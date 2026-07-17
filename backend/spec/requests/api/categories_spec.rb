require 'rails_helper'

RSpec.describe "Api::Categories", type: :request do
  describe "GET /api/categories" do
    let!(:food) { Category.create!(name: "Food") }
    let!(:transport) { Category.create!(name: "Transport") }
    let!(:supplies) { Category.create!(name: "Supplies") }

    it "returns all categories" do
      get "/api/categories"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json.map { |c| c["name"] }).to include("Food", "Transport", "Supplies")
    end

    it "returns categories in alphabetical order" do
      get "/api/categories"

      json = JSON.parse(response.body)
      expect(json.map { |c| c["name"] }).to eq([ "Food", "Supplies", "Transport" ])
    end
  end

  describe "POST /api/categories" do
    it "creates a category" do
      expect {
        post "/api/categories", params: { category: { name: "Subscriptions" } }, as: :json
      }.to change(Category, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json).to include("id" => Category.last.id, "name" => "Subscriptions")
    end

    it "rejects a blank category name" do
      expect {
        post "/api/categories", params: { category: { name: "   " } }, as: :json
      }.not_to change(Category, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Name can't be blank")
    end

    it "rejects a category name longer than 100 characters" do
      expect {
        post "/api/categories", params: { category: { name: "a" * 101 } }, as: :json
      }.not_to change(Category, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Name is too long (maximum is 100 characters)")
    end

    it "rejects a duplicate category name" do
      Category.create!(name: "Food")

      expect {
        post "/api/categories", params: { category: { name: "Food" } }, as: :json
      }.not_to change(Category, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Name has already been taken")
    end
  end
end
