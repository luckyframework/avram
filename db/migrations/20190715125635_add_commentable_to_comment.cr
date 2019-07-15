class AddCommentableToComment::V20190715125635 < Avram::Migrator::Migration::V1
  def migrate
    alter :comments do
      add_polymorphic_belongs_to :commentable, foreign_key_type: Int64, optional: false
      add_polymorphic_belongs_to :optional_commentable, foreign_key_type: Int64, optional: true
    end
  end

  def rollback
    alter :comments do
      remove_polymorphic_belongs_to :commentable
      remove_polymorphic_belongs_to :optional_commentable
    end
  end
end
