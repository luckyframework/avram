require "./index_statement_helpers"

class Avram::Migrator::CreateTableStatement
  include Avram::Migrator::IndexStatementHelpers

  private getter rows = [] of String

  def initialize(@table_name : Symbol)
  end

  # Accepts a block to build a table and indices using `add` and `add_index` methods.
  #
  # The generated sql statements are aggregated in the `statements` method.
  #
  # ## Usage
  #
  # ```
  # built = Avram::Migrator::CreateTableStatement.new(:users).build do
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
  # built = Avram::Migrator::CreateTableStatement.new(:users, PrimaryKeyType::UUID).build do
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
      statement << rows.join(",\n")
      statement << ");"
    end
  end

  private def initial_table_statement
    <<-SQL
    CREATE TABLE #{@table_name} (\n
    SQL
  end

  macro primary_key(type_declaration)
    rows << Avram::Migrator::Columns::PrimaryKeys::{{ type_declaration.type }}PrimaryKey
      .new(name: {{ type_declaration.var.stringify }})
      .build
  end

  macro add_timestamps
    add created_at : Time
    add updated_at : Time
  end

  macro add(type_declaration, default = nil, index = false, unique = false, using = :btree, **type_options)
    {% if type_declaration.type.is_a?(Union) %}
      {% type = type_declaration.type.types.first %}
      {% nilable = true %}
      {% array = false %}
    {% elsif type_declaration.type.is_a?(Generic) %}
      {% type = type_declaration.type.type_vars.first %}
      {% nilable = false %}
      {% array = true %}
    {% else %}
      {% type = type_declaration.type %}
      {% nilable = false %}
      {% array = false %}
    {% end %}

    rows << Avram::Migrator::Columns::{{ type }}Column(
    {% if array %}Array({% end %}{{ type }}{% if array %}){% end %}
    ).new(
      name: {{ type_declaration.var.stringify }},
      nilable: {{ nilable }},
      default: {{ default }},
      {{ **type_options }}
    )
    {% if array %}
    .array!
    {% end %}
    .build_add_statement_for_create

    {% if index || unique %}
      add_index :{{ type_declaration.var }}, using: {{ using }}, unique: {{ unique }}
    {% end %}
  end

  # Adds a references column and index given a model class and references option.
  macro add_belongs_to(type_declaration, on_delete, references = nil, foreign_key_type = Int64)
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
    %table_name = {{ references }} || Wordsmith::Inflector.pluralize({{ underscored_class }})

    rows << Avram::Migrator::Columns::{{ foreign_key_type }}Column({{ foreign_key_type }}).new(
      name: {{ foreign_key_name.stringify }},
      nilable: {{ optional }},
      default: nil,
    )
    .set_references(references: %table_name.to_s, on_delete: {{ on_delete }})
    .build_add_statement_for_create

    add_index :{{ foreign_key_name }}
  end

  macro add_polymorphic_belongs_to(type_declaration, foreign_key_type = Int64, optional = false)
    add {{ type_declaration.id }}_id : {{ foreign_key_type }}{% if optional %}?{% end %}
    add {{ type_declaration.id }}_type : String{% if optional %}?{% end %}

    add_index [:{{ type_declaration.id }}_id, :{{ type_declaration.id }}_type], unique: false
  end

  macro add_belongs_to(_type_declaration, references = nil)
    {% raise "Must use 'on_delete' when creating an add_belongs_to association.
      Example: add_belongs_to user : User, on_delete: :cascade" %}
  end
end
