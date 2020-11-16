class MenuOption < BaseModel
  skip_default_columns

  table do
    primary_key id : Int16
    timestamps

    column title : String
    column option_value : Int16
  end
end
