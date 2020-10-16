class AddFloatArrayToBuckets::V20200821135952 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(Bucket) do
      add floaty_numbers : Array(Float64), fill_existing_with: [0.0]
    end
  end

  def rollback
    alter table_for(Bucket) do
      remove :floaty_numbers
    end
  end
end
