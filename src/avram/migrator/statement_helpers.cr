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

  def create_foreign_key(from : Symbol, to : Symbol, on_delete : Symbol, column : Symbol?, primary_key = :id)
    prepared_statements << CreateForeignKeyStatement.new(from, to, on_delete, column, primary_key).build
  end

  def create_index(table_name : Symbol, columns : Columns, unique = false, using = :btree, name : String? | Symbol? = nil)
    prepared_statements << CreateIndexStatement.new(table_name, columns, using, unique, name).build
  end

  def drop_index(table_name : Symbol, columns : Columns? = nil, if_exists = false, on_delete = :do_nothing, name : String? | Symbol? = nil)
    prepared_statements << Avram::Migrator::DropIndexStatement.new(table_name, columns, if_exists, on_delete, name).build
  end

  def make_required(table : Symbol, column : Symbol)
    prepared_statements << Avram::Migrator::ChangeNullStatement.new(table, column, required: true).build
  end

  def make_optional(table : Symbol, column : Symbol)
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
end
