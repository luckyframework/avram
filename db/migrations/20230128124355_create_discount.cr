class CreateDiscount::V20230128124355 < Avram::Migrator::Migration::V1
  def migrate
    create :discounts do
      primary_key id : String
      add_timestamps
      add description : String
      add in_cents : Int32
      add_belongs_to line_item : LineItem, on_delete: :cascade, foreign_key_type: UUID
    end
  end

  def rollback
    drop :discounts
  end
end
