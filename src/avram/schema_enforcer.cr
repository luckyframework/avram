module Avram::SchemaEnforcer
  ALL_MODELS     = [] of Avram::Model.class
  MODELS_TO_SKIP = [] of String # Stringified class name

  macro setup(table_name, columns, type, *args, **named_args)
    def self.ensure_correct_column_mappings!
      return if Avram::SchemaEnforcer::MODELS_TO_SKIP.includes?(self.name)

      attributes = [
        {% for attribute in columns %}
          { name: :{{attribute[:name]}}, nilable: {{ attribute[:nilable] }}, type: {{ attribute[:type].id }}.name },
        {% end %}
      ]

      EnsureExistingTable.new(model_class: {{ type.id }}).validate!
      EnsureMatchingColumns.new(model_class: {{ type.id }}, attributes: attributes).validate!
    end

    {% if !type.resolve.abstract? %}
      {% Avram::SchemaEnforcer::ALL_MODELS << type %}
    {% end %}
  end

  def self.ensure_correct_column_mappings!
    {% if !ALL_MODELS.empty? %}
      ALL_MODELS.each do |model|
        model.ensure_correct_column_mappings!
      end
    {% end %}
  end

  macro skip_schema_enforcer
    {% Avram::SchemaEnforcer::MODELS_TO_SKIP << @type.stringify %}
  end

  abstract class Validation
    private getter model_class : Avram::Model.class
    private getter database_info : Avram::Database::DatabaseInfo

    def initialize(@model_class)
      @database_info = @model_class.database.database_info
    end

    abstract def validate!

    private def table_name
      model_class.table_name.to_s
    end
  end

  class EnsureExistingTable < Validation
    def validate!
      if table_missing?
        best_match = Levenshtein::Finder.find table_name, database_info.table_names, tolerance: 2

        message = String.build do |string|
          string << "#{model_class.name.colorize.bold} wants to use the '#{table_name.colorize.bold}' table but it is missing.\n"

          if best_match
            string << <<-TEXT

            If you meant for #{model_class.name.colorize.bold} to use the '#{best_match.colorize.yellow.bold}' table, try this...

              ▸ Change the table name in #{model_class.name.colorize.bold}:

                  table :#{best_match.colorize.bold} do
                    # ..columns
                  end

            TEXT
          end

          string << <<-TEXT

          If you need to create the '#{table_name}' table...

            ▸ Generate a migration:

                lucky gen.migration Create#{Wordsmith::Inflector.pluralize(model_class.name)}

            ▸ Create the table in the migration:

                create table_for(#{model_class.name}) do/end

          TEXT

          string << <<-TEXT

          Or, you can skip schema checks for this model:

              class #{model_class.name} < BaseModel
                # Great for models used in migrations, or for legacy schemas
                skip_schema_enforcer
              end


          TEXT
        end

        raise Avram::SchemaMismatchError.new(message)
      end
    end

    private def table_missing?
      !database_info.table?(table_name)
    end
  end

  class EnsureMatchingColumns < Validation
    private getter table_info : Database::TableInfo
    private getter attributes : Array({name: Symbol, nilable: Bool, type: String})
    @missing_columns = [] of String
    @optional_attribute_errors = [] of String
    @required_attribute_errors = [] of String

    def initialize(model_class, @attributes)
      initialize model_class
      @table_info = database_info.table(table_name).not_nil!
    end

    def validate!
      attributes.each do |attribute|
        check_column_matches attribute
      end

      if matching_error?
        message = @missing_columns + @optional_attribute_errors + @required_attribute_errors

        raise Avram::SchemaMismatchError.new(message.join("\n\n"))
      end
    end

    private def check_column_matches(attribute)
      unless column = table_info.column(attribute[:name].to_s)
        @missing_columns << missing_attribute_error(table_info.table_name, table_info.column_names, attribute)
        return
      end

      if !attribute[:nilable] && column.nilable?
        @required_attribute_errors << required_attribute_error(table_info.table_name, attribute)
      elsif attribute[:nilable] && !column.nilable?
        @optional_attribute_errors << optional_attribute_error(table_info.table_name, attribute)
      end
    end

    private def matching_error?
      @missing_columns.any? || @optional_attribute_errors.any? || @required_attribute_errors.any?
    end

    private def missing_attribute_error(table_name, column_names, missing_attribute)
      message = "#{model_class.name.colorize.bold} wants to use the column '#{missing_attribute[:name].to_s.colorize.bold}' but it does not exist."
      best_match = Levenshtein::Finder.find missing_attribute[:name].to_s, column_names, tolerance: 2

      if best_match
        message += " Did you mean '#{best_match.colorize.yellow.bold}'?\n\n"
      else
        message += <<-TEXT


        Try adding the column to the table...

          ▸ Generate a migration:

              lucky gen.migration Add#{Wordsmith::Inflector.classify(missing_attribute[:name])}To#{Wordsmith::Inflector.pluralize(model_class.name)}

          ▸ Add the column to the migration:

              alter :#{table_name} do
                #{"# Add the column:".colorize.dim}
                add #{missing_attribute[:name]} : #{missing_attribute[:type]}

                #{"# Or if this is a column for a belongs_to relationship:".colorize.dim}
                add_belongs_to #{missing_attribute[:name]} : #{missing_attribute[:type]}
              end

        Or, you can skip schema checks for this model:

            class #{model_class.name} < BaseModel
              # Great for models used in migrations, or for legacy schemas
              skip_schema_enforcer
            end


        TEXT
      end

      message
    end

    private def optional_attribute_error(table_name, attribute)
      <<-ERROR
      #{model_class.name.colorize.bold} has defined '#{attribute[:name].to_s.colorize.bold}' as nilable (#{attribute[:type]}?), but the database column does not allow nils.

      Either mark the column as required in #{model_class.name.colorize.bold}:

        #{"# Remove the '?'".colorize.dim}
        column #{attribute[:name]} : #{attribute[:type]}

      Or, make the column optional in a migration:

        ▸ Generate a migration:

            lucky gen.migration Make#{model_class.name}#{Wordsmith::Inflector.classify(attribute[:name])}Optional

        ▸ Make the column optional:

            make_optional :#{table_name}, :#{attribute[:name]}

      Alternatively, you can skip schema checks for this model:

          class #{model_class.name} < BaseModel
            # Great for models used in migrations, or for legacy schemas
            skip_schema_enforcer
          end


      ERROR
    end

    private def required_attribute_error(table_name, attribute)
      <<-ERROR
      #{model_class.name.colorize.bold} has defined '#{attribute[:name].to_s.colorize.bold}' as required (#{attribute[:type]}), but the database column does allow nils.

      Either mark the column as optional in #{model_class.name.colorize.bold}:

        #{"# Add '?' to the  end of the type".colorize.bold}
        column #{attribute[:name]} : #{attribute[:type]}?

      Or, make the column required in a migration:

        ▸ Generate a migration:

            lucky gen.migration Make#{model_class.name}#{Wordsmith::Inflector.classify(attribute[:name])}Required

        ▸ Make the column required:

            make_required :#{table_name}, :#{attribute[:name]}

      Alternatively, you can skip schema checks for this model:

        class #{model_class.name} < BaseModel
          # Great for models used in migrations, or use with legacy schemas
          skip_schema_enforcer
        end


      ERROR
    end
  end
end
