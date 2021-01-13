class AddArrayUuidToBuckets::V20210108124932 < Avram::Migrator::Migration::V1
  def migrate
    uuids = [] of UUID
    alter table_for(Bucket) do
      add oody_things : Array(UUID), default: uuids
    end
  end

  def rollback
    alter table_for(Bucket) do
      remove :oody_things
    end
  end
end
