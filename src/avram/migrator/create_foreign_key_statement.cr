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
    String.build do |index|
      index << "ALTER TABLE"
      index << ' ' << @from
      index << " ADD CONSTRAINT " << @from << '_'
      foreign_key(index)
      index << "_fk"
      index << " FOREIGN KEY ("
      foreign_key(index)
      index << ')'
      reference_fragment(index)
      index << ';'
    end
  end

  private def reference_fragment(io)
    BuildReferenceFragment.new("#{@to} (#{@primary_key})", @on_delete).build(io)
  end

  private def foreign_key(io)
    if @column
      io << @column
    else
      Wordsmith::Inflector.singularize(io, @to.to_s)
      io << "_id"
    end
  end
end
