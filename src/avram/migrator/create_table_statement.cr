require "./index_statement_helpers"
require "./missing_on_delete_with_belongs_to_error"

class Avram::Migrator::CreateTableStatement
  include Avram::Migrator::IndexStatementHelpers
  include Avram::Migrator::MissingOnDeleteWithBelongsToError

  private getter rows = [] of String
  private getter constraints = [] of String

  def initialize(@table_name : TableName)
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
  def build(&) : CreateTableStatement
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
      statement << ",\n" if !constraints.empty?
      statement << constraints.join(", \n")
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

  macro composite_primary_key(*columns)
    {% if columns.size < 2 %}
    {% raise "composite_primary_key expected at least two primary keys, instead got #{columns.size}" %}
    {% end %}
    constraints << "  PRIMARY KEY ({{columns.join(", ").id}})"
  end

  macro add_timestamps
    add created_at : Time, default: :now
    add updated_at : Time, default: :now
  end

  macro add(type_declaration, default = nil, index = false, unique = false, using = :btree, **type_options)
    {%
      type = type_declaration.type.resolve
      nilable = false
      array = false
      bytes = false
    %}
    {%
      if type.nilable?
        type = type.union_types.reject(&.==(Nil)).first
        nilable = true
      end
    %}
    {%
      if type < Array
        type = type.type_vars.first
        array = true
      end
    %}
    {%
      if type < Slice
        type = "Bytes".id
        bytes = true
      end
    %}


    rows << Avram::Migrator::Columns::{{ type }}Column(
    {% if array %}Array({{ type }}){% else %}{{ type }}{% end %}
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
  macro add_belongs_to(type_declaration, on_delete, references = nil, foreign_key_type = Int64, unique = false)
    {% unless type_declaration.is_a?(TypeDeclaration) %}
      {% raise "add_belongs_to expected a type declaration like 'user : User', instead got: '#{type_declaration}'" %}
    {% end %}
    {% if type_declaration.type.stringify =~ /\w::\w/ && references.nil? %}
      {% raise <<-ERROR
      Namespaced models must include the `references` option with the name of the table.

      Try this...

        ▸ add_belongs_to(#{type_declaration}, on_delete: #{on_delete}, references: :the_table_name)
      ERROR
      %}
    {% end %}
    {% optional = type_declaration.type.is_a?(Union) %}

    {% if optional %}
      {% underscored_class = type_declaration.type.types.first %}
    {% else %}
      {% underscored_class = type_declaration.type %}
    {% end %}
    {% underscored_class = underscored_class.stringify.underscore.gsub(/::/, "_") %}

    {% foreign_key_name = type_declaration.var + "_id" %}
    %table_name = {{ references }} || Wordsmith::Inflector.pluralize({{ underscored_class }})

    rows << Avram::Migrator::Columns::{{ foreign_key_type }}Column({{ foreign_key_type }}).new(
      name: {{ foreign_key_name.stringify }},
      nilable: {{ optional }},
      default: nil,
    )
    .set_references(references: %table_name.to_s, on_delete: {{ on_delete }})
    .build_add_statement_for_create

    add_index :{{ foreign_key_name }}, unique: {{ unique }}
  end

  macro belongs_to(type_declaration, *args, **named_args)
    {% raise <<-ERROR
      Unexpected call to `belongs_to` in a migration.
      Found in #{type_declaration.filename.id}:#{type_declaration.line_number}:#{type_declaration.column_number}.

      Did you mean to use 'add_belongs_to'?

      'add_belongs_to #{type_declaration}, ...'
      ERROR
    %}
  end
end
