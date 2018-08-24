class CreateLineItem::V20180625202051 < LuckyRecord::Migrator::Migration::V1
  def migrate
    create :line_items, primary_key_type: :uuid do
      add name : String
    end
  end

  def rollback
    drop :line_items
  end
end
