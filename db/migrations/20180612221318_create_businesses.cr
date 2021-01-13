class CreateBusinesses::V20180612221318 < Avram::Migrator::Migration::V1
  def migrate
    create :businesses do
      primary_key id : Int64
      add_timestamps
      add name : String
    end

    create :tax_ids do
      primary_key id : Int64
      add_timestamps
      add number : Int32
      add_belongs_to business : Business, on_delete: :cascade
    end

    enable_extension "citext"

    create :email_addresses do
      primary_key id : Int64
      add_timestamps
      add address : String, case_sensitive: false
      add_belongs_to business : Business?, on_delete: :cascade
    end
  end

  def rollback
    drop :tax_ids
    drop :email_addresses
    drop :businesses
  end
end
