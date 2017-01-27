class CreateUsers::V20170127143149 < LuckyMigrator::Migration::V1
  def migrate
    execute <<-SQL
      CREATE TABLE users (
        id serial PRIMARY KEY,
        name text NOT NULL,
        created_at timestamp NOT NULL,
        updated_at timestamp NOT NULL,
        age int NOT NULL,
        nickname text,
        joined_at timestamp NOT NULL
      )
    SQL
  end

  def rollback
    execute <<-SQL
      DROP TABLE users
    SQL
  end
end
