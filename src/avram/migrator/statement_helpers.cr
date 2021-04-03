require "./index_statement_helpers"

module Avram::Migrator::StatementHelpers
  include Avram::Migrator::IndexStatementHelpers
  include Avram::TableFor

  macro create(table_name)
    statements = Avram::Migrator::CreateTableStatement.new({{ table_name }}).build do
      {{ yield }}
    end.statements

    statements.each do |statement|
      prepared_statements << statement
    end
  end

  def drop(table_name)
    prepared_statements << Avram::Migrator::DropTableStatement.new(table_name).build
  end

  macro alter(table_name)
    statements = Avram::Migrator::AlterTableStatement.new({{ table_name }}).build do
      {{ yield }}
    end.statements

    statements.each do |statement|
      prepared_statements <<  statement
    end
  end

  def create_foreign_key(from : TableName, to : TableName, on_delete : Symbol, column : Symbol?, primary_key = :id)
    prepared_statements << CreateForeignKeyStatement.new(from, to, on_delete, column, primary_key).build
  end

  def drop_foreign_key(from : TableName, references : TableName, column : Symbol?)
    prepared_statements << DropForeignKeyStatement.new(from, references, column).build
  end

  def create_index(table_name : TableName, columns : Columns, unique = false, using = :btree, name : String? | Symbol? = nil)
    prepared_statements << CreateIndexStatement.new(table_name, columns, using, unique, name).build
  end

  def drop_index(table_name : TableName, columns : Columns? = nil, if_exists = false, on_delete = :do_nothing, name : String? | Symbol? = nil)
    prepared_statements << Avram::Migrator::DropIndexStatement.new(table_name, columns, if_exists, on_delete, name).build
  end

  def make_required(table : TableName, column : Symbol)
    prepared_statements << Avram::Migrator::ChangeNullStatement.new(table, column, required: true).build
  end

  def make_optional(table : TableName, column : Symbol)
    prepared_statements << Avram::Migrator::ChangeNullStatement.new(table, column, required: false).build
  end

  def enable_extension(name : String)
    prepared_statements << Avram::Migrator::CreateExtensionStatement.new(name).build
  end

  def disable_extension(name : String)
    prepared_statements << Avram::Migrator::DropExtensionStatement.new(name).build
  end

  def update_extension(name : String, to : String? = nil)
    prepared_statements << Avram::Migrator::AlterExtensionStatement.new(name, to: to).build
  end

  def create_function(name : String, body : String, returns : String = "trigger")
    prepared_statements << Avram::Migrator::CreateFunctionStatement.new(name, body: body, returns: returns).build
  end

  def drop_function(name : String)
    prepared_statements << Avram::Migrator::DropFunctionStatement.new(name).build
  end

  # Drop any existing trigger by this name first before creating.
  # Postgres does not support updating or replacing a trigger as of version 12
  #
  # Creates a new TRIGGER named `name` on the table `table_name`.
  # `function_name` - The PG function to run from this trigger.
  # `callback` - When to run this trigger (BEFORE or AFTER). Default `:before`
  # `on` - The operation(s) for this trigger (INSERT, UPDATE, DELETE). Default is `[:update]`
  #
  # ```
  # create_trigger(:users, "trigger_set_timestamps", "set_timestamps")
  # # => CREATE TRIGGER trigger_set_timestamps BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE set_timestamps();
  # ```
  def create_trigger(table_name : TableName, name : String, function_name : String, callback : Symbol = :before, on : Array(Symbol) = [:update])
    drop_trigger(table_name, name)
    prepared_statements << Avram::Migrator::CreateTriggerStatement.new(table_name, name, function_name, callback, on).build
  end

  # Drop the tigger `name` for the table `table_name`
  def drop_trigger(table_name : TableName, name : String)
    prepared_statements << Avram::Migrator::DropTriggerStatement.new(table_name, name).build
  end
end
