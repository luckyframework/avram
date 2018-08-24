require "./index_statement_helpers"

# Builds an SQL statement for creating an index using table name, column
# name(s), index type and unique flag.
#
# ### Usage
#
# For a single column:
#
# ```
# CreateIndexStatement.new(:users, columns: :email, using: :btree, unique: true).build
# # => "CREATE UNIQUE INDEX users_email_index ON users USING btree (email);"
# ```
#
# For multiple columns:
#
# ```
# CreateIndexStatement.new(:users, columns: [:email, :username], using: :btree, unique: true).build
# # => "CREATE UNIQUE INDEX users_email_username_index ON users USING btree (email, username);"
# ```
class LuckyRecord::Migrator::CreateIndexStatement
  include LuckyRecord::Migrator::IndexStatementHelpers

  ALLOWED_INDEX_TYPES = %w[btree]

  def initialize(@table : Symbol, @columns : Columns, @using : Symbol = :btree, @unique = false)
    raise "index type '#{using}' not supported" unless ALLOWED_INDEX_TYPES.includes?(using.to_s)
  end

  def build
    String.build do |index|
      index << "CREATE"
      index << " UNIQUE" if @unique
      index << " INDEX #{@table}_#{columns.join("_")}_index"
      index << " ON #{@table}"
      index << " USING #{@using}"
      index << " (#{columns.join(", ")});"
    end
  end

  private def columns
    columns = @columns

    if columns.is_a? Array
      return columns
    else
      return [columns]
    end
  end
end
