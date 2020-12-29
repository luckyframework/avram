class CreateLineItem::V20180625202051 < Avram::Migrator::Migration::V1
  def migrate
    enable_extension "pgcrypto"

    create :line_items do
      primary_key id : UUID
      add_timestamps
      add name : String
    end
  end

  def rollback
    drop :line_items
  end
end
