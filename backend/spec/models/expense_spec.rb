require 'rails_helper'

RSpec.describe Expense, type: :model do
  let(:category) { Category.create!(name: "Food") }

  it "accepts today's date" do
    expense = Expense.new(
      description: "Lunch",
      amount: 100.00,
      category: category,
      date: Date.current
    )

    expect(expense).to be_valid
  end

  it "accepts a past date" do
    expense = Expense.new(
      description: "Lunch",
      amount: 100.00,
      category: category,
      date: Date.current - 1.day
    )

    expect(expense).to be_valid
  end

  it "rejects a future date" do
    expense = Expense.new(
      description: "Lunch",
      amount: 100.00,
      category: category,
      date: Date.current + 1.day
    )

    expect(expense).to be_invalid
    expect(expense.errors[:date]).to include("cannot be in the future")
  end
end
