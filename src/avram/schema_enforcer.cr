module Avram::SchemaEnforcer
  MODELS_TO_ENFORCE = [] of Avram::Model.class

  macro setup(table_name, columns, type, *args, **named_args)
    include Avram::SchemaEnforcer
    def self.ensure_correct_column_mappings!
      attributes = [
        {% for attribute in columns %}
          { name: :{{attribute[:name]}}, nilable: {{ attribute[:nilable] }}, type: {{ attribute[:type] }} },
        {% end %}
      ]

      EnsureExistingTable.new(
        model_class: {{ type }},
        table_name: :{{table_name}},
        database: {{ type }}.database
      ).ensure_exists!
      EnsureMatchingColumns.new(
        model_class: {{ type }},
        table_name: :{{table_name}},
        database: {{ type }}.database
      ).ensure_matches! attributes
    end

    {% if !type.resolve.abstract? %}
      {% Avram::SchemaEnforcer::MODELS_TO_ENFORCE << type %}
    {% end %}
  end

  def self.ensure_correct_column_mappings!
    MODELS_TO_ENFORCE.each do |model_type|
      model_type.ensure_correct_column_mappings!
    end
  end

  class EnsureExistingTable
    private getter table_name, model_class
    @table_names : Array(String)

    def initialize(@model_class : Avram::Model.class,
                   @table_name : Symbol,
                   @database : Avram::Database.class)
      @table_names = @database.new.tables_with_schema(excluding: "migrations")
    end

    def ensure_exists!
      if table_missing?
        best_match = Levenshtein::Finder.find @table_name.to_s, @table_names, tolerance: 2
        message = String.build do |message|
          message << "#{@model_class.to_s.colorize.bold} wants to use the '#{table_name.colorize.bold}' table but it is missing.\n"

          if best_match
            message << <<-TEXT

            If you meant for #{model_class.to_s.colorize.bold} to use the '#{best_match.colorize.yellow.bold}' table, try this...

              ▸ Change the table name in #{model_class.to_s.colorize.bold}:

                  table :#{best_match} do
                    #{"# ..columns".colorize.dim}
                  end

            TEXT
          end

          message << <<-TEXT

          If you need to create the '#{table_name}' table...

            ▸ Generate a migration:

                lucky gen.migration Create#{Wordsmith::Inflector.pluralize(model_class.name.to_s)}

            ▸ Create the table in the migration:

                create :#{table_name} do/end


          TEXT
        end

        raise Avram::SchemaMismatchError.new(message)
      end
    end

    private def table_missing?
      !@table_names.includes?(@table_name.to_s)
    end
  end

  class EnsureMatchingColumns
    private getter model_class, table_name
    @columns_map = Hash(String, Bool).new
    @missing_columns = [] of String
    @optional_attribute_errors = [] of String
    @required_attribute_errors = [] of String

    def initialize(@model_class : Avram::Model.class,
                   @table_name : Symbol,
                   @database : Avram::Database.class)
      columns = @database.new.table_columns(table_name)
      columns.each do |column|
        @columns_map[column.name] = column.nilable
      end
    end

    def ensure_matches!(attributes)
      attributes.each do |attribute|
        check_column_matches attribute
      end

      if matching_error?
        message = @missing_columns + @optional_attribute_errors + @required_attribute_errors

        raise Avram::SchemaMismatchError.new(message.join("\n\n"))
      end
    end

    private def check_column_matches(attribute)
      unless @columns_map.has_key? attribute[:name].to_s
        @missing_columns << missing_attribute_error(@table_name, @columns_map.keys, attribute)
        return
      end

      if !attribute[:nilable] && @columns_map[attribute[:name].to_s]
        @required_attribute_errors << required_attribute_error(@table_name, attribute)
      elsif attribute[:nilable] && !@columns_map[attribute[:name].to_s]
        @optional_attribute_errors << optional_attribute_error(@table_name, attribute)
      end
    end

    private def matching_error?
      @missing_columns.any? || @optional_attribute_errors.any? || @required_attribute_errors.any?
    end

    private def missing_attribute_error(table_name, column_names, missing_attribute)
      message = "#{model_class.to_s.colorize.bold} wants to use the column '#{missing_attribute[:name].to_s.colorize.bold}' but it does not exist."
      best_match = Levenshtein::Finder.find missing_attribute[:name].to_s, column_names, tolerance: 2

      if best_match
        message += " Did you mean '#{best_match.colorize.yellow.bold}'?\n\n"
      else
        message += <<-TEXT


        Try adding the column to the table...

          ▸ Generate a migration:

              lucky gen.migration Add#{Wordsmith::Inflector.classify(missing_attribute[:name])}To#{Wordsmith::Inflector.pluralize(model_class)}

          ▸ Add the column to the migration:

              alter :#{table_name} do
                #{"# Add the column:".colorize.dim}
                add #{missing_attribute[:name]} : #{missing_attribute[:type]}

                #{"# Or if this is a column for a belongs_to relationship:".colorize.dim}
                add_belongs_to #{missing_attribute[:name]} : #{missing_attribute[:type]}
              end


        TEXT
      end
    end

    private def optional_attribute_error(table_name, attribute)
      <<-ERROR
      #{model_class.to_s.colorize.bold} has defined '#{attribute[:name].to_s.colorize.bold}' as nilable (#{attribute[:type]}?), but the database column does not allow nils.

      Either mark the column as required in #{model_class.to_s.colorize.bold}:

        #{"# Remove the '?'".colorize.dim}
        column #{attribute[:name]} : #{attribute[:type]}

      Or, make the column optional in a migration:

        ▸ Generate a migration:

            lucky gen.migration Make#{model_class}#{Wordsmith::Inflector.classify(attribute[:name])}Optional

        ▸ Make the column optional:

            make_optional :#{table_name}, :#{attribute[:name]}


      ERROR
    end

    private def required_attribute_error(table_name, attribute)
      <<-ERROR
      #{model_class.to_s.colorize.bold} has defined '#{attribute[:name].to_s.colorize.bold}' as required (#{attribute[:type]}), but the database column does allow nils.

      Either mark the column as optional in #{model_class.to_s.colorize.bold}:

        #{"# Add '?' to the  end of the type".colorize.bold}
        column #{attribute[:name]} : #{attribute[:type]}?

      Or, make the column required in a migration:

        ▸ Generate a migration:

            lucky gen.migration Make#{model_class}#{Wordsmith::Inflector.classify(attribute[:name])}Required

        ▸ Make the column required:

            make_required :#{table_name}, :#{attribute[:name]}


      ERROR
    end
  end
end
