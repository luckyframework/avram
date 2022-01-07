class TestChangeType::V20190723233131 < Avram::Migrator::Migration::V1
  # Test that we can save and query after type changes
  class TempUserInt64 < Avram::Model
    skip_default_columns

    def self.database
      TestDatabase
    end

    table :users do
      primary_key id : Int64
      column name : String
      column age : Int32
      column joined_at : Time
      timestamps
    end
  end

  def migrate
    TempUserInt64::SaveOperation.create!(name: "foo", age: 0, joined_at: Time.utc)

    alter table_for(User) do
      change_type id : Int32
    end

    alter table_for(User) do
      change_type id : Int64
    end

    TempUserInt64::BaseQuery.first.delete # should not raise
  end

  def rollback
  end
end
