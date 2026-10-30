# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id, type: :Bignum
      column :avatar_url, String
      column :created_at, :timestamptz, null: false
      column :email, String
      column :github_uid, String, null: false
      column :name, String
      column :updated_at, :timestamptz, null: false
      column :username, String, null: false
      index :github_uid, unique: true, name: :index_users_on_github_uid
    end
  end

  down do
    drop_table(:users)
  end
end
