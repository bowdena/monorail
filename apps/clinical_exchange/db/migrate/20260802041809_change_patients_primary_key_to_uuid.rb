class ChangePatientsPrimaryKeyToUuid < ActiveRecord::Migration[8.1]
  def up
    add_column :patients, :uuid, :uuid, default: -> { "uuidv7()" },
      null: false
    remove_column :patients, :id
    rename_column :patients, :uuid, :id
    execute "ALTER TABLE patients ADD PRIMARY KEY (id)"
  end

  def down
    remove_column :patients, :id
    add_column :patients, :id, :primary_key
  end
end
