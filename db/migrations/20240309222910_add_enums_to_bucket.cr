class AddEnumsToBucket::V20240309222910 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(Bucket) do
      add enums : Array(Int32), default: [] of Int32
    end
  end

  def rollback
    alter table_for(Bucket) do
      remove :enums
    end
  end
end
