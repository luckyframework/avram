class AddNonModelFieldToUsers::V20180102195309 < Avram::Migrator::Migration::V1
  def migrate
    alter :users do
      add not_added_to_model_definition : String?
    end
  end

  def rollback
    alter :users do
      remove :not_added_to_model_definition
    end
  end
end
