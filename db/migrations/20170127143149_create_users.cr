class CreateUsers::V20170127143149 < LuckyRecord::Migrator::Migration::V1
  def migrate
    create :users do
      add name : String
      add nickname : String?
      add age : Int32
      add joined_at : Time
    end
  end

  def rollback
    drop :users
  end
end
