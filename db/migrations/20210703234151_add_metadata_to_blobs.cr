class AddMetadataToBlobs::V20210703234151 < Avram::Migrator::Migration::V1
  def migrate
    alter :blobs do
      add metadata : JSON::Any, default: JSON::Any.new({} of String => JSON::Any)
      add media : JSON::Any?, fill_existing_with: :nothing
    end
  end

  def rollback
    alter :blobs do
      remove :metadata
      remove :media
    end
  end
end
