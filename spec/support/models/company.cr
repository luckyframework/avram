class Company < BaseModel
  table do
    column sales : Int64 = 0_i64
    column earnings : Float64 = 0.0
  end
end
