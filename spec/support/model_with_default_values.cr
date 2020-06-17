# columns in migration defined with default values
# db/migrations/20180802180357_test_defaults.cr
class ModelWithDefaultValues < BaseModel

  table :test_defaults do
    column greeting : String # default: "Hello there!"
    column drafted_at : Time # default: :now
    column published_at : Time # default: 1.day.from_now
    column admin : Bool # default: false
    column age : Int32 # default: 30
    column money : Float64 # default: 3.5
  end
end
