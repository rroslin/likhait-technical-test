class Api::ExpensesController < ApplicationController
  SORTABLE_COLUMNS = %w[date created_at].freeze
  SORT_DIRECTIONS = %w[asc desc].freeze

  def index
    return render_invalid_sort if invalid_sort_params?

    expenses = Expense.includes(:category).order(expense_order)

    if params[:year].present? && params[:month].present?
      year = params[:year].to_i
      month = params[:month].to_i

      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      expenses = expenses.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    render json: expenses.map { |expense| format_expense(expense) }
  end

  def create
    expense = Expense.new(expense_params)

    if expense.save
      render json: format_expense(expense), status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    expense = Expense.find(params[:id])

    if expense.update(expense_params)
      render json: format_expense(expense)
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    expense = Expense.find(params[:id])
    expense.destroy
    head :no_content
  end

  private

  def invalid_sort_params?
    return false unless params[:sort_by].present? || params[:sort_order].present?

    !SORTABLE_COLUMNS.include?(params[:sort_by]) || !SORT_DIRECTIONS.include?(params[:sort_order])
  end

  def render_invalid_sort
    render json: { error: "sort_by must be one of: #{SORTABLE_COLUMNS.join(', ')} and sort_order must be one of: #{SORT_DIRECTIONS.join(', ')}" }, status: :bad_request
  end

  def expense_order
    return { created_at: :desc } unless params[:sort_by].present?

    direction = params[:sort_order].to_sym

    if params[:sort_by] == "date"
      { date: direction, created_at: direction, id: direction }
    else
      { created_at: direction, id: direction }
    end
  end

  def expense_params
    params.require(:expense).permit(:description, :amount, :category_id, :date)
  end

  def format_expense(expense)
    {
      id: expense.id,
      description: expense.description,
      amount: expense.amount.to_f,
      category: expense.category.name,
      date: expense.date.to_s,
      created_at: expense.created_at,
      updated_at: expense.updated_at
    }
  end
end
