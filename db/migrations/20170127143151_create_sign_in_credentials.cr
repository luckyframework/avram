class CreateSignInCredentials::V20170127143151 < LuckyRecord::Migrator::Migration::V1
  def migrate
    create :sign_in_credentials do
      add user_id : Int32
    end
  end

  def rollback
    drop :sign_in_credentials
  end
end
