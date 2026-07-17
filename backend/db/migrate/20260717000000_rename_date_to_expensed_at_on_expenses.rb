class RenameDateToExpensedAtOnExpenses < ActiveRecord::Migration[7.2]
  def change
    rename_column :expenses, :date, :expensed_at
  end
end
