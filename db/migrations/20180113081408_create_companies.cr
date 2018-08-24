class CreateCompanies::V20180113081408 < LuckyRecord::Migrator::Migration::V1
  def migrate
    create :companies do
      add sales : Int64
      add earnings : Float
    end
  end

  def rollback
    drop :companies
  end
end
