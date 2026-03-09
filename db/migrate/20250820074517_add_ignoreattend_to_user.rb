class AddIgnoreattendToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :ignore_attend, :string
  end
end
