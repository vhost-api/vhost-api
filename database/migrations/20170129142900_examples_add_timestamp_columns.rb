# frozen_string_literal: true
Sequel.migration do
  change do
    add_column :examples, :created_at, Integer
    set_column_default :examples, :created_at, Time.now.to_i
    add_column :examples, :updated_at, Integer
    set_column_default :examples, :updated_at, Time.now.to_i
    from(:examples).update(created_at: Time.now.to_i)
    from(:examples).update(updated_at: Time.now.to_i)
  end
end
