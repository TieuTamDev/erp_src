class AddTimeToScheduleweek < ActiveRecord::Migration[5.0]
  def change
    add_column :scheduleweeks, :time_required, :string
    add_column :scheduleweeks, :time_register, :string
    add_column :scheduleweeks, :time_worked, :string
  end
end
