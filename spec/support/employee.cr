class Employee < BaseModel
  table do
    column name : String
    belongs_to manager : Manager?
    has_many comments : Comment, polymorphic: :commentable
  end
end
