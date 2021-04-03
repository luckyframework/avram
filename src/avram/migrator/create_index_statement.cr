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
#
# With custom name:
#
# ```
# CreateIndexStatement.new(:users, columns: [:email, :username], name: :custom_index_name).build
# # => "CREATE INDEX custom_index_name ON users USING btree (email, username);"
# ```
class Avram::Migrator::CreateIndexStatement
  include Avram::Migrator::IndexStatementHelpers

  ALLOWED_INDEX_TYPES = %w[btree]

  def initialize(@table : TableName, @columns : Columns, @using : Symbol = :btree, @unique = false, @name : String? | Symbol? = nil)
    raise "index type '#{using}' not supported" unless ALLOWED_INDEX_TYPES.includes?(using.to_s)
  end

  def build
    index_name = @name
    index_name ||= "#{@table}_#{columns.join("_")}_index"

    String.build do |index|
      index << "CREATE"
      index << " UNIQUE" if @unique
      index << " INDEX #{index_name}"
      index << " ON #{@table}"
      index << " USING #{@using}"
      index << " (#{columns.join(", ")});"
    end
  end

  private def columns
    columns = @columns

    if columns.is_a? Array
      columns
    else
      [columns]
    end
  end
end
