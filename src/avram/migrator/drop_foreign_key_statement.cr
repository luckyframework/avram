# Generates an ALTER TABLE statement for dropping a foreign key constraint on a table.
#
# ### Usage
#
# ```
# DropForeignKeyStatement.new(from: :comments, references: :users, column: :author_id).build
# # => "ALTER TABLE comments DROP CONSTRAINT comments_author_id_fk;"
# ```
class Avram::Migrator::DropForeignKeyStatement
  def initialize(@from : TableName, @references : TableName, @column : Symbol? = nil)
  end

  def build
    String.build do |index|
      index << "ALTER TABLE"
      index << ' ' << @from
      index << " DROP CONSTRAINT " << @from << '_'
      foreign_key(index)
      index << "_fk" << ';'
    end
  end

  private def foreign_key(io)
    if @column
      io << @column
    else
      Wordsmith::Inflector.singularize(io, @references.to_s)
      io << "_id"
    end
  end
end
