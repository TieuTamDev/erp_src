class CreateMsettings < ActiveRecord::Migration[5.0]
  def change
    create_table :msettings do |t|
      t.string :stype
      t.string :name
      t.string :scode
      t.text :svalue
      t.datetime :valid_from
      t.datetime :valid_to

      t.timestamps
    end
  end
end
