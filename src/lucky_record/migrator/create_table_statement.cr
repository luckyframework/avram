require "./references_helper"
require "./index_statement_helpers"

class LuckyRecord::Migrator::CreateTableStatement
  include LuckyRecord::Migrator::IndexStatementHelpers
  include LuckyRecord::Migrator::ColumnDefaultHelpers
  include LuckyRecord::Migrator::ColumnTypeOptionHelpers
  include LuckyRecord::Migrator::ReferencesHelper

  private getter rows = [] of String

  def initialize(@table_name : Symbol, @primary_key_type : PrimaryKeyType = PrimaryKeyType::Serial)
  end

  # Accepts a block to build a table and indices using `add` and `add_index` methods.
  #
  # The generated sql statements are aggregated in the `statements` method.
  #
  # ## Usage
  #
  # ```
  # built = LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
  #   add_belongs_to Account, on_delete: :cascade
  #   add :email : String, unique: true
  # end
  #
  # built.statements
  # # => [
  #   "CREATE TABLE users (
  #     id serial PRIMARY KEY,
  #     created_at timestamptz NOT NULL,
  #     updated_at timestamptz NOT NULL,
  #     account_id bigint NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  #     email text NOT NULL);",
  #   "CREATE UNIQUE INDEX users_email_index ON users USING btree (email);"
  # ]
  # ```
  #
  # An optional second argument can toggle between the usage of a numeric or uuid
  # based id column.
  #
  # ```
  # built = LuckyRecord::Migrator::CreateTableStatement.new(:users, PrimaryKeyType::UUID).build do
  #   add :email : String, unique: true
  # end
  # ```
  def build : CreateTableStatement
    with self yield
    self
  end

  def statements
    [table_statement] + index_statements
  end

  private def table_statement
    String.build do |statement|
      statement << initial_table_statement
      statement << ",\n" unless rows.empty?

      statement << rows.join(",\n")
      statement << ");"
    end
  end

  private def initial_table_statement
    id_column_type = if @primary_key_type == PrimaryKeyType::UUID
                       "uuid"
                     else
                       "serial"
                     end
    <<-SQL
    CREATE TABLE #{@table_name} (
      id #{id_column_type} PRIMARY KEY,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    SQL
  end

  # Generates raw sql from a type declaration and options passed in as named
  # variables.
  macro add(type_declaration, index = false, using = :btree, unique = false, default = nil, **type_options)
    {% options = type_options.empty? ? nil : type_options %}

    {% if type_declaration.type.is_a?(Union) %}
      add_column :{{ type_declaration.var }}, {{ type_declaration.type.types.first }}, optional: true, default: {{ default }}, options: {{ options }}
    {% else %}
      add_column :{{ type_declaration.var }}, {{ type_declaration.type }}, default: {{ default }}, options: {{ options }}
    {% end %}

    {% if index || unique %}
      add_index :{{ type_declaration.var }}, using: {{ using }}, unique: {{ unique }}
    {% end %}
  end

  def add_column(name, type : ColumnType, optional = false, reference = nil, on_delete = :do_nothing, default : ColumnDefaultType? = nil, options : NamedTuple? = nil)
    if options
      column_type_with_options = column_type(type, **options)
    else
      column_type_with_options = column_type(type)
    end

    rows << String.build do |row|
      row << "  "
      row << name.to_s
      row << " "
      row << column_type_with_options
      row << null_fragment(optional)
      row << default_value(type, default) unless default.nil?
      row << references(reference, on_delete)
    end
  end

  # Adds a references column and index given a model class and references option.
  macro add_belongs_to(type_declaration, on_delete, references = nil, foreign_key_type = LuckyRecord::Migrator::PrimaryKeyType::Serial)
    {% unless type_declaration.is_a?(TypeDeclaration) %}
      {% raise "add_belongs_to expected a type declaration like 'user : User', instead got: '#{type_declaration}'" %}
    {% end %}
    {% optional = type_declaration.type.is_a?(Union) %}

    {% if optional %}
      {% underscored_class = type_declaration.type.types.first.stringify.underscore %}
    {% else %}
      {% underscored_class = type_declaration.type.stringify.underscore %}
    {% end %}

    {% foreign_key_name = type_declaration.var + "_id" %}
    %table_name = {{ references }} || LuckyInflector::Inflector.pluralize({{ underscored_class }})
    add_column(:{{ foreign_key_name }}, {{ foreign_key_type.id }}.db_type, {{ optional }}, reference: %table_name, on_delete: {{ on_delete }})
    add_index :{{ foreign_key_name }}
  end

  macro add_belongs_to(_type_declaration, references = nil)
    {% raise "Must use 'on_delete' when creating an add_belongs_to association.
      Example: add_belongs_to user : User, on_delete: :cascade" %}
  end

  def null_fragment(optional)
    if optional
      ""
    else
      " NOT NULL"
    end
  end
end
