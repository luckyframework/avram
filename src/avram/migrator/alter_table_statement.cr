require "./index_statement_helpers"

class Avram::Migrator::AlterTableStatement
  include Avram::Migrator::IndexStatementHelpers

  getter rows = [] of String
  getter dropped_rows = [] of String
  getter fill_existing_with_statements = [] of String

  def initialize(@table_name : Symbol)
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
    [alter_statement] + index_statements + fill_existing_with_statements
  end

  def alter_statement
    String.build do |statement|
      statement << "ALTER TABLE #{@table_name}"
      statement << "\n"
      statement << (rows + dropped_rows).join(",\n")
    end
  end

  # Adds a references column and index given a model class and references option.
  macro add_belongs_to(type_declaration, on_delete, references = nil, foreign_key_type = Int32)
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

  macro add_belongs_to(_type_declaration, references = nil)
    {% raise "Must use 'on_delete' when creating an add_belongs_to association.
      Example: add_belongs_to user : User, on_delete: :cascade" %}
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
      {% nilable = false %}
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

  macro add_polymorphic_belongs_to(type_declaration, foreign_key_type = Int64, optional = false)
    add {{ type_declaration.id }}_id : {{ foreign_key_type }}{% if optional %}?{% end %}, fill_existing_with: :nothing
    add {{ type_declaration.id }}_type : String{% if optional %}?{% end %}, fill_existing_with: :nothing

    add_index [:{{ type_declaration.id }}_id, :{{ type_declaration.id }}_type], unique: false
  end

  def add_fill_existing_with_statements(column : Symbol | String, type, value)
    @fill_existing_with_statements += [
      "UPDATE #{@table_name} SET #{column} = #{value.to_s};",
      "ALTER TABLE #{@table_name} ALTER COLUMN #{column} SET NOT NULL;",
    ]
  end

  def remove(name : Symbol)
    dropped_rows << "  DROP #{name.to_s}"
  end

  macro remove_belongs_to(association_name)
    {% unless association_name.is_a?(SymbolLiteral) %}
      {% raise "remove_belongs_to expected a symbol like ':user', instead got: '#{association_name}'" %}
    {% end %}
    remove {{ association_name }}_id
  end

  macro remove_polymorphic_belongs_to(association_name)
    {% unless association_name.is_a?(SymbolLiteral) %}
      {% raise "remove_belongs_to expected a symbol like ':user', instead got: '#{association_name}'" %}
    {% end %}
    remove {{ association_name }}_id
    remove {{ association_name }}_type

    drop_index([:{{ association_name.id }}_id, :{{ association_name.id }}_type], if_exists: true)
  end
end
