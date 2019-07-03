class Blob < Avram::Model
  table do
    column doc : JSON::Any?
  end
end
