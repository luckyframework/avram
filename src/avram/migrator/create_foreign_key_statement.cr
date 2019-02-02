# Generates an ALTER TABLE statement for adding a foreign key constraint on a table.
#
# ### Usage
#
# ```
# CreateForeignKeyStatement.new(from: :comments, to: :users, column: :author_id, primary_key: :uid, on_delete: :cascade).build
# # => "ALTER TABLE comments ADD CONSTRAINT comments_author_id_fk FOREIGN KEY (author_id) REFERENCES users (uid) ON DELETE CASCADE;"
# ```
class Avram::Migrator::CreateForeignKeyStatement
  include ReferencesHelper

  def initialize(@from : Symbol, @to : Symbol, @on_delete : Symbol, @column : Symbol? = nil, @primary_key = :id)
  end

  def build
    foreign_key = @column || Wordsmith::Inflector.singularize(@to.to_s) + "_id"
    String.build do |index|
      index << "ALTER TABLE"
      index << " #{@from}"
      index << " ADD CONSTRAINT #{@from}_#{foreign_key}_fk"
      index << " FOREIGN KEY (#{foreign_key})"
      index << " REFERENCES #{@to} (#{@primary_key})"
      index << on_delete_strategy(@on_delete)
      index << ";"
    end
  end

  def on_delete_strategy(strategy : Symbol)
    if strategy == :do_nothing
      return ""
    else
      return " ON DELETE " + on_delete_sql(strategy)
    end
  end
end
