class Company < BaseModel
  COLUMN_SQL = %("companies"."id", "companies"."created_at", "companies"."updated_at", "companies"."sales", "companies"."earnings")
  table do
    column sales : Int64 = 0_i64
    column earnings : Float64 = 0.0
  end
end
