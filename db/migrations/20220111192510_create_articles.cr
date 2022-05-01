class CreateArticles::V20220111192510 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Article) do
      primary_key id : Int64
      add_timestamps
      add title : String
      add sub_heading : String?
      add slug : String
    end
  end

  def rollback
    drop table_for(Article)
  end
end
