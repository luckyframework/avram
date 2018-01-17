class CreateTaggings::V20180115194734 < LuckyMigrator::Migration::V1
  def migrate
    create :tags do
      add name : String
    end

    create :taggings do
      belongs_to Tag, on_delete: :cascade
      belongs_to Post, on_delete: :cascade
    end
  end

  def rollback
    drop :taggings
    drop :tags
  end
end
