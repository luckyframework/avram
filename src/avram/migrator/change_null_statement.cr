# Builds an SQL statement for changing a columns NOT NULL status.
#
# ### Usage
#
# ```
# ChangeNullStatement.new(:users, :email, required: false).build
# # => "ALTER TABLE users ALTER COLUMN email DROP NOT NULL;"
# ```
class Avram::Migrator::ChangeNullStatement
  def initialize(@table : TableName, @column : Symbol, @required : Bool)
  end

  def build
    if @required
      change = "SET"
    else
      change = "DROP"
    end

    column = PG::EscapeHelper.escape_identifier(@column.to_s)

    String.build do |index|
      index << "ALTER TABLE " << @table
      index << " ALTER COLUMN " << column
      index << ' ' << change << " NOT NULL;"
    end
  end
end
