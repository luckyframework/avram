require "./index_statement_helpers"

# Builds an SQL statement for dropping an index by inferring it's name using table name and column(s).
#
# ### Usage
#
# For a single column index:
#
# ```
# DropIndexStatement.new(:users, :email, if_exists: true, on_delete: :cascade).build
# # => "DROP INDEX IF EXISTS users_email_index CASCADE;"
# ```
#
# For multiple column index:
#
# ```
# DropIndexStatement.new(:users, [:email, :username] if_exists: true, on_delete: :cascade).build
# # => "DROP INDEX IF EXISTS users_email_username_index CASCADE;"
# ```
#
# For index by name:
#
# ```
# DropIndexStatement.new(:users, name: :custom_index_name).build
# # => "DROP INDEX custom_index_name;"
# ```
class Avram::Migrator::DropIndexStatement
  include Avram::Migrator::IndexStatementHelpers

  ALLOWED_ON_DELETE_STRATEGIES = %i[cascade restrict]

  def initialize(@table : TableName, @columns : Columns? = nil, @if_exists = false, @on_delete = :do_nothing, @name : String? | Symbol? = nil)
  end

  def build
    String.build do |index|
      index << "DROP INDEX"
      index << " IF EXISTS" if @if_exists
      index << " #{index_name}"
      index << on_delete_strategy(@on_delete)
    end
  end

  def on_delete_strategy(on_delete = :do_nothing)
    if on_delete == :do_nothing
      ";"
    elsif ALLOWED_ON_DELETE_STRATEGIES.includes?(on_delete)
      " #{on_delete};".upcase
    else
      raise "on_delete: :#{on_delete} is not supported. Please use :do_nothing, :cascade or :restrict"
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

  private def index_name
    if @name || @columns
      @name.to_s.presence || "#{@table}_#{columns.join("_")}_index"
    else
      raise "No name or columns specified for drop_index"
    end
  end
end
