class AddMetadataToBlobs::V20210703234151 < Avram::Migrator::Migration::V1
  def migrate
    alter :blobs do
      # Serialized columns should end in _raw to differentiate between
      # the original raw data, and the serialized object
      add metadata_raw : JSON::Any, default: JSON::Any.new({} of String => JSON::Any)
    end
  end

  def rollback
    alter :blobs do
      remove :metadata_raw
    end
  end
end
