class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.string :urn, null: false
      t.string :first_name
      t.string :last_name, null: false
      t.date :date_of_birth
      t.string :gender
      t.string :atsi_status
      t.string :merged_from

      t.timestamps
    end
    add_index :patients, :urn, unique: true
  end
end
