class CreateReporttmps < ActiveRecord::Migration[5.0]
  def change
    create_table :reporttmps do |t|
      t.string :name
      t.string :filepath
      t.datetime :valid_from
      t.datetime :valid_to
      t.string :lang
      t.string :dept
      t.text :note
      t.string :status

      t.timestamps
    end
  end
end
