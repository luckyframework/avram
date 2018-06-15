class CreateTaggings::V20180115194734 < LuckyMigrator::Migration::V1
  def migrate
    create :tags do
      add name : String
    end

    create :taggings do
      add_belongs_to tag : Tag, on_delete: :cascade
      add_belongs_to post : Post, on_delete: :cascade
    end
  end

  def rollback
    drop :taggings
    drop :tags
  end
end
