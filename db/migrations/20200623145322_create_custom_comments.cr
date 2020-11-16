class CreateCustomComments::V20200623145322 < Avram::Migrator::Migration::V1
  def migrate
    create :custom_comments do
      primary_key custom_id : UUID
      add_timestamps
      add body : String
    end
  end

  def rollback
    drop :custom_comments
  end
end
