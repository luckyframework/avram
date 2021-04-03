# Generates an ALTER TABLE statement for adding a foreign key constraint on a table.
#
# ### Usage
#
# ```
# CreateForeignKeyStatement.new(from: :comments, to: :users, column: :author_id, primary_key: :uid, on_delete: :cascade).build
# # => "ALTER TABLE comments ADD CONSTRAINT comments_author_id_fk FOREIGN KEY (author_id) REFERENCES users (uid) ON DELETE CASCADE;"
# ```
class Avram::Migrator::CreateForeignKeyStatement
  def initialize(@from : TableName, @to : TableName, @on_delete : Symbol, @column : Symbol? = nil, @primary_key = :id)
  end

  def build
    foreign_key = @column || Wordsmith::Inflector.singularize(@to.to_s) + "_id"
    String.build do |index|
      index << "ALTER TABLE"
      index << " #{@from}"
      index << " ADD CONSTRAINT #{@from}_#{foreign_key}_fk"
      index << " FOREIGN KEY (#{foreign_key})"
      index << BuildReferenceFragment.new("#{@to} (#{@primary_key})", @on_delete).build
      index << ";"
    end
  end
end
