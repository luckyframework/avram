class AddJsonArrayToBlob::V20230624134902 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(Blob) do
      add servers : JSON::Any, default: JSON::Any.new({} of String => JSON::Any)
    end
  end

  def rollback
    alter table_for(Blob) do
      remove :servers
    end
  end
end
