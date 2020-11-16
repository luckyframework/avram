class Blob < BaseModel
  table do
    column doc : JSON::Any?
  end
end
