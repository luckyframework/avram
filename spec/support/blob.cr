class Blob < Avram::Model
  table blobs do
    column doc : JSON::Any?
  end
end
