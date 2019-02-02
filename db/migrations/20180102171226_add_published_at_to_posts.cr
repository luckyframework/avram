class AddPublishedAtToPosts::V20180102171226 < Avram::Migrator::Migration::V1
  def migrate
    alter :posts do
      add published_at : Time?
    end
  end

  def rollback
    alter :posts do
      remove :published_at
    end
  end
end
