# frozen_string_literal: true
Sequel.migration do
  change do
    create_table(:example) do
      primary_key :id
      String :name, null: false
    end
  end
end
