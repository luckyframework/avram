class Employee < BaseModel
  COLUMN_SQL = %("employees"."id", "employees"."created_at", "employees"."updated_at", "employees"."name", "employees"."manager_id")
  table do
    column name : String
    belongs_to manager : Manager?
    has_many customers : Customer
  end
end
