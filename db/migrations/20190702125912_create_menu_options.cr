class CreateMenuOptions::V20190702125912 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(MenuOption) do
      primary_key id : Int16
      add_timestamps
      add title : String
      add option_value : Int16
    end
  end

  def rollback
    drop :menu_options
  end
end
