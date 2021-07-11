class AddConstraintComments::V20210710000000 < Avram::Migrator::Migration::V1
  def migrate
    execute <<-SQL
      ALTER TABLE comments
        ADD CONSTRAINT fk_columns_has_post
        FOREIGN KEY (post_id)
        REFERENCES posts (custom_id);
    SQL
  end

  def rollback
    execute <<-SQL
      ALTER TABLE comments
      DROP CONSTRAINT fk_columns_has_post;
    SQL
  end
end
