# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:documents) do
      primary_key :id, type: :Bignum
      column :attachment_data, String
      column :byte_count, :Bignum, null: true
      column :created_at, :timestamptz, null: false
      column :processed_at, :timestamptz, null: true
      column :updated_at, :timestamptz, null: false
    end
  end

  down do
    drop_table(:documents)
  end
end
