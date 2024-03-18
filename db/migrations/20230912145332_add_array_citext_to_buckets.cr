class AddArrayCitextToBuckets::V20230912145332 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(Bucket) do
      add tags : Array(String), default: [] of String, case_sensitive: false
    end
  end

  def rollback
    alter table_for(Bucket) do
      remove :tags
    end
  end
end
