class CreateTaggings::V20180115194734 < Avram::Migrator::Migration::V1
  def migrate
    create :tags do
      primary_key custom_id : Int64
      add_timestamps
      add name : String
    end

    create :taggings do
      primary_key id : Int64
      add_timestamps
      add_belongs_to tag : Tag, on_delete: :cascade
      add_belongs_to post : Post, on_delete: :cascade
    end
  end

  def rollback
    drop :taggings
    drop :tags
  end
end
