class Name < BaseModel
  view :all_the_names, materialized: true do
    column name : String
  end
end
