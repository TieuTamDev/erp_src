class AddIgnoreattendToPositionjob < ActiveRecord::Migration[5.0]
  def change
    add_column :positionjobs, :ignore_attend, :string
  end
end
