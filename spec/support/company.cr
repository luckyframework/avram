class Company < Avram::Model
  table companies do
    column sales : Int64
    column earnings : Float64
  end
end
