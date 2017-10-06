class CreatePostsAndComments::V20171006163153 < LuckyMigrator::Migration::V1
  def migrate
    create :posts do
      add title : String
    end

    create :comments do
      add body : String
      add post_id : Int32
    end
  end

  def rollback
    drop :posts
    drop :comments
  end
end
