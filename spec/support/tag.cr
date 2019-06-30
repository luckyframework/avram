class Tag < Avram::Model
  skip_default_columns

  table :tags do
    primary_key custom_id : Int64
    timestamps
    column name : String
    has_many taggings : Tagging
  end
end
