class CreateBlobs::V20180802180356 < Avram::Migrator::Migration::V1
  def migrate
    create :blobs do
      primary_key id : Int64
      add_timestamps
      add doc : JSON::Any?, default: JSON::Any.new({"defa'ult" => JSON::Any.new("val'ue")})
    end
  end

  def rollback
    drop :blobs
  end
end
