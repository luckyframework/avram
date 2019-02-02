class CreateBusinesses::V20180612221318 < Avram::Migrator::Migration::V1
  def migrate
    create :businesses do
      add name : String
    end

    create :tax_ids do
      add number : Int32
      add_belongs_to business : Business, on_delete: :cascade
    end

    create :email_addresses do
      add address : String
      add_belongs_to business : Business?, on_delete: :cascade
    end
  end

  def rollback
    drop :tax_ids
    drop :email_addresses
    drop :businesses
  end
end
