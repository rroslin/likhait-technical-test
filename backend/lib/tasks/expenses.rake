namespace :expenses do
  desc "Audit future-dated expenses; set APPLY=true to move them to today"
  task fix_future_dates: :environment do
    target_date = Date.current
    future_expenses = Expense.where("date > ?", target_date)
    affected_count = future_expenses.count

    puts "Found #{affected_count} expense(s) dated after #{target_date}."

    if ENV["APPLY"] != "true"
      future_expenses.find_each do |expense|
        puts "Would update expense ##{expense.id}: #{expense.date} -> #{target_date}"
      end
      puts "Dry run only. Re-run with APPLY=true to update these expenses."
      next
    end

    updated_count = 0
    future_expenses.find_each do |expense|
      previous_date = expense.date

      if expense.update(date: target_date)
        updated_count += 1
        puts "Updated expense ##{expense.id}: #{previous_date} -> #{target_date}"
      else
        puts "Skipped expense ##{expense.id}: #{expense.errors.full_messages.join(', ')}"
      end
    end

    puts "Updated #{updated_count} of #{affected_count} future-dated expense(s)."
  end
end
