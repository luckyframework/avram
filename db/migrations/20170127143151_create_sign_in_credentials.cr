class CreateSignInCredentials::V20170127143151 < Avram::Migrator::Migration::V1
  def migrate
    create :sign_in_credentials do
      primary_key id : Int64
      add_timestamps
      add user_id : Int64
      add value : String
    end
  end

  def rollback
    drop :sign_in_credentials
  end
end
