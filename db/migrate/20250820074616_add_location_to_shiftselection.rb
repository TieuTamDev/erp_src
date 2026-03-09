class AddLocationToShiftselection < ActiveRecord::Migration[5.0]
  def change
    add_column :shiftselections, :location, :string
  end
end
