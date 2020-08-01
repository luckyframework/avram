require "./index_statement_helpers"
require "./missing_on_delete_with_belongs_to_error"

class Avram::Migrator::AlterTableStatement
  include Avram::Migrator::IndexStatementHelpers
  include Avram::Migrator::MissingOnDeleteWithBelongsToError

  getter rows = [] of String
  getter renamed_rows = [] of String
  getter dropped_rows = [] of String
  getter fill_existing_with_statements = [] of String
  getter change_type_statements = [] of String

  def initialize(@table_name : Symbol)
  end

  macro change_type(type_declaration, **type_options)
    {% if !type_declaration.is_a?(TypeDeclaration) %}
      {% type_declaration.raise "Must pass a type declaration to 'change_type'. Example: change_type age : Int32" %}
    {% end %}
    %column = ::Avram::Migrator::Columns::{{ type_declaration.type }}Column({{ type_declaration.type }}).new(
      name: {{ type_declaration.var.stringify }},
      nilable: false,
      default: nil,
      {{ **type_options }}
    )
    add_change_type_statement %column
  end

  def add_change_type_statement(column : ::Avram::Migrator::Columns::Base)
    change_type_statements << column.build_change_type_statement(@table_name)
  end

  # Accepts a block to alter a table using the `add` method. The generated sql
  # statements are aggregated in the `statements` getter.
  #
  # ## Usage
  #
  # ```
  # built = Avram::Migrator::AlterTableStatement.new(:users).build do
  #   add name : String
  #   add age : Int32
  #   remove old_field
  # end
  #
  # built.statements
  # # => [
  # "ALTER TABLE users
  #   ADD name text NOT NULL,
  #   ADD age int NOT NULL,
  #   DROP old_field"
  # ]
  # ```
  def build
    with self yield
    self
  end

  def statements
    alter_statements + change_type_statements + index_statements + fill_existing_with_statements
  end

  def alter_statements : Array(String)
    alterations = renamed_rows.map do |statement|
      "ALTER TABLE #{@table_name} #{statement};"
    end
    unless (rows + dropped_rows).empty?
      alterations << String.build do |statement|
        statement << "ALTER TABLE #{@table_name}"
        statement << "\n"
        statement << (rows + dropped_rows).join(",\n")
        statement << ';'
      end
    end
    alterations
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

    rows << ::Avram::Migrator::Columns::{{ foreign_key_type }}Column({{ foreign_key_type }}).new(
      name: {{ foreign_key_name.stringify }},
      nilable: {{ optional }},
      default: nil
    )
    .set_references(references: %table_name.to_s, on_delete: {{ on_delete }})
    .build_add_statement_for_alter

    add_index :{{ foreign_key_name }}
  end

  macro add(type_declaration, index = false, using = :btree, unique = false, default = nil, fill_existing_with = nil, **type_options)
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
      {% nilable = (fill_existing_with != nil) && (fill_existing_with != :nothing) %}
      {% array = false %}
    {% end %}

    {% if !nilable && default == nil && fill_existing_with == nil %}
      {% raise <<-ERROR

        You must provide a default value or use fill_existing_with when adding a required column to an existing table.

        Try one of these...

          ▸ add #{type_declaration.var} : #{type}, default: "Something"
          ▸ add #{type_declaration.var} : #{type}, fill_existing_with: "Something"
          ▸ add #{type_declaration.var} : #{type}, fill_existing_with: :nothing
        ERROR
      %}
    {% end %}

    {% if default && fill_existing_with %}
      {% type_declaration.raise "Cannot use both 'default' and 'fill_existing_with' arguments" %}
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
    .build_add_statement_for_alter

    {% if fill_existing_with && fill_existing_with != :nothing %}
      add_fill_existing_with_statements(
        column: {{ type_declaration.var.stringify }},
        type: {{ type }},
        value: Avram::Migrator::Columns::{{ type }}Column.prepare_value_for_database({{ fill_existing_with }})
      )
    {% end %}

    {% if index || unique %}
      add_index :{{ type_declaration.var }}, using: {{ using }}, unique: {{ unique }}
    {% end %}
  end

  def add_fill_existing_with_statements(column : Symbol | String, type, value)
    @fill_existing_with_statements += [
      "UPDATE #{@table_name} SET #{column} = #{value};",
      "ALTER TABLE #{@table_name} ALTER COLUMN #{column} SET NOT NULL;",
    ]
  end

  {% symbol_expected_message = "%s expected a symbol like ':user', instead got: '%s'" %}

  macro rename(old_name, new_name)
    {% for name in {old_name, new_name} %}
      {% unless name.is_a?(SymbolLiteral) %}
        {% raise symbol_expected_message % {"rename", name} %}
      {% end %}
    {% end %}
    renamed_rows << "RENAME COLUMN #{{{old_name}}} TO #{{{new_name}}}"
  end

  macro rename_belongs_to(old_association_name, new_association_name)
    {% for association_name in {old_association_name, new_association_name} %}
      {% unless association_name.is_a?(SymbolLiteral) %}
        {% raise symbol_expected_message % {"rename_belongs_to", association_name} %}
      {% end %}
    {% end %}
    rename {{old_association_name}}_id, {{new_association_name}}_id
  end

  macro remove(name)
    {% unless name.is_a?(SymbolLiteral) %}
      {% raise symbol_expected_message % {"remove", name} %}
    {% end %}
    dropped_rows << "  DROP #{{{name}}}"
  end

  macro remove_belongs_to(association_name)
    {% unless association_name.is_a?(SymbolLiteral) %}
      {% raise symbol_expected_message % {"remove_belongs_to", association_name} %}
    {% end %}
    remove {{ association_name }}_id
  end
end
