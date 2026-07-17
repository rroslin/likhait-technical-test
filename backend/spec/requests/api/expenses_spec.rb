require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
    let!(:expense1) do
      Expense.create!(
        description: "Lunch",
        amount: 100.00,
        category: food_category,
        date: Date.new(2026, 1, 15),
        created_at: Time.zone.parse("2026-01-20 09:00:00")
      )
    end
    let!(:expense2) do
      Expense.create!(
        description: "Taxi",
        amount: 50.00,
        category: transport_category,
        date: Date.new(2026, 1, 16),
        created_at: Time.zone.parse("2026-01-20 10:00:00")
      )
    end

    it "returns all expenses with category information" do
      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "returns expenses in descending order by created_at" do
      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(expense2.id)
      expect(json.last["id"]).to eq(expense1.id)
    end

    it "sorts by expense date when requested" do
      get "/api/expenses", params: { sort_by: "date", sort_order: "desc" }

      json = JSON.parse(response.body)
      expect(json.map { |expense| expense["id"] }).to eq([expense2.id, expense1.id])
    end

    it "uses created_at and id as tie-breakers when sorting by date" do
      earlier_expense = Expense.create!(
        description: "Earlier entry",
        amount: 75.00,
        category: food_category,
        date: Date.new(2026, 1, 17),
        created_at: Time.zone.parse("2026-01-20 08:00:00")
      )
      later_expense = Expense.create!(
        description: "Later entry",
        amount: 125.00,
        category: food_category,
        date: Date.new(2026, 1, 17),
        created_at: Time.zone.parse("2026-01-20 11:00:00")
      )

      get "/api/expenses", params: { sort_by: "date", sort_order: "desc" }

      json = JSON.parse(response.body)
      same_date_ids = json.filter_map do |expense|
        expense["id"] if [earlier_expense.id, later_expense.id].include?(expense["id"])
      end
      expect(same_date_ids).to eq([later_expense.id, earlier_expense.id])
    end

    it "rejects invalid sorting parameters" do
      get "/api/expenses", params: { sort_by: "amount", sort_order: "sideways" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to include("sort_by must be one of")
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.today
          }
        }
      end

      it "creates a new expense" do
        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq(150.5)
      end
    end

    context "with invalid parameters" do
      it "with negative amounts" do
        invalid_params = {
          expense: {
            description: "Invalid expense",
            amount: -100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "with empty descriptions" do
        invalid_params = {
          expense: {
            description: "",
            amount: 100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end
end
