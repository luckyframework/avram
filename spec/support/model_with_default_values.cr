# columns in migration defined with default values
# db/migrations/20180802180357_test_defaults.cr
class ModelWithDefaultValues < BaseModel
  table :test_defaults do
    column greeting : String = "Hello there!"
    column drafted_at : Time = Time.utc
    column published_at : Time = 1.day.from_now
    column admin : Bool = false
    column age : Int32 = 30
    column money : Float64 = 3.5
  end
end
