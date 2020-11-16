class CreateBucketsWithArrayTypes::V20190712145900 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Bucket) do
      primary_key id : Int64
      add_timestamps
      add bools : Array(Bool)
      add small_numbers : Array(Int16)
      add numbers : Array(Int32)?
      add big_numbers : Array(Int64)
      add names : Array(String)
    end
  end

  def rollback
    drop :buckets
  end
end
