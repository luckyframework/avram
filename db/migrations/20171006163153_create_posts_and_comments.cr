class CreatePostsAndComments::V20171006163153 < Avram::Migrator::Migration::V1
  def migrate
    create :posts do
      primary_key id : Int32
      add_timestamps
      add title : String
    end

    create :comments do
      primary_key id : Int32
      add_timestamps
      add body : String
      add post_id : Int32
    end
  end

  def rollback
    drop :posts
    drop :comments
  end
end
