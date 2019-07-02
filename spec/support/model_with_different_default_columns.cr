# Different primary key name
# No timestamps
class ModelWithDifferentDefaultColumns < Avram::Model
  skip_default_columns

  table :table_with_different_default_columns do
    primary_key custom_id : Int64
    column name : String
  end
end
