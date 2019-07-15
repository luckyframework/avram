class Company < BaseModel
  table do
    column sales : Int64
    column earnings : Float64
    has_many comments : Comment, polymorphic: :commentable
  end
end
