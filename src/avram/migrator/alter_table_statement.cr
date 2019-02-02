require "./column_default_helpers"
require "./column_type_option_helpers"
require "./index_statement_helpers"
require "./references_helper"

class Avram::Migrator::AlterTableStatement
  include Avram::Migrator::IndexStatementHelpers
  include Avram::Migrator::ColumnTypeOptionHelpers
  include Avram::Migrator::ColumnDefaultHelpers
  include Avram::Migrator::ReferencesHelper

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
  macro add_belongs_to(type_declaration, on_delete, references = nil, foreign_key_type = Avram::Migrator::PrimaryKeyType::Serial)
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

    add_index :{{ foreign_key_name }}
    add_column :{{ foreign_key_name }},
      type: {{ foreign_key_type }}.db_type,
      optional: {{ optional }},
      default: nil,
      fill_existing_with: nil,
      reference: %table_name,
      on_delete: {{ on_delete }},
      options: nil
  end

  macro add_belongs_to(_type_declaration, references = nil)
    {% raise "Must use 'on_delete' when creating an add_belongs_to association.
      Example: add_belongs_to user : User, on_delete: :cascade" %}
  end

  macro add(type_declaration, index = false, using = :btree, unique = false, default = nil, fill_existing_with = nil, **type_options)
    {% options = type_options.empty? ? nil : type_options %}

    {% if type_declaration.type.is_a?(Union) %}
      add_column :{{ type_declaration.var }}, {{ type_declaration.type.types.first }}, true, {{ default }}, nil, options: {{ options }}
    {% else %}
      {% if default == nil && fill_existing_with == nil %}
        {% raise <<-ERROR

          You must provide a default value or use fill_existing_with when adding a required field to an existing table.

          Try one of these...

            ▸ add #{type_declaration.var} : #{type_declaration.type}, default: "Something"
            ▸ add #{type_declaration.var} : #{type_declaration.type}, fill_existing_with: "Something"
            ▸ add #{type_declaration.var} : #{type_declaration.type}, fill_existing_with: :nothing
          ERROR
        %}
      {% end %}

      {% if default && fill_existing_with %}
        {% type_declaration.raise "Cannot use both 'default' and 'fill_existing_with' arguments" %}
      {% end %}

      {% if fill_existing_with == :nothing %}
        {% fill_existing_with = nil %}
      {% end %}

      add_column :{{ type_declaration.var }},
        type: {{ type_declaration.type }},
        optional: false,
        default: {{ default }},
        fill_existing_with: {{ fill_existing_with }},
        options: {{ options }}
    {% end %}

    {% if index || unique %}
      add_index :{{ type_declaration.var }}, using: {{ using }}, unique: {{ unique }}
    {% end %}
  end

  def add_column(name : Symbol, type : ColumnType, optional = false, reference = nil, on_delete = :do_nothing, default : ColumnDefaultType? = nil, fill_existing_with : ColumnDefaultType? = nil, options : NamedTuple? = nil)
    if options
      column_type_with_options = column_type(type, **options)
    else
      column_type_with_options = column_type(type)
    end

    if fill_existing_with
      optional = true
      add_fill_existing_with_statements(name, type, fill_existing_with)
    end

    rows << String.build do |row|
      row << "  ADD "
      row << name.to_s
      row << " "
      row << column_type_with_options
      row << null_fragment(optional)
      row << default_value(type, default) unless default.nil?
      row << references(reference, on_delete)
    end
  end

  def add_fill_existing_with_statements(column : Symbol, type : ColumnType, value : ColumnDefaultType)
    @fill_existing_with_statements += [
      "UPDATE #{@table_name} SET #{column} = #{value_to_string(type, value)};",
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

  def null_fragment(optional)
    if optional
      ""
    else
      " NOT NULL"
    end
  end
end
