class DifferentDefaults::V20180802180358 < Avram::Migrator::Migration::V1
  def migrate
    create :table_with_different_default_columns do
      # Different name for primary key
      # And no timestamps
      primary_key custom_id : Int64
      add name : String?
    end
  end

  def rollback
    drop :table_with_different_default_columns
  end
end
