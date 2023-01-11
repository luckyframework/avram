class Avram::SchemaEnforcer::EnsureMatchingColumns < Avram::SchemaEnforcer::Validation
  @check_required : Bool
  @missing_columns = [] of String
  @optional_attribute_errors = [] of String
  @required_attribute_errors = [] of String

  def initialize(model_class)
    initialize(model_class, check_required: true)
  end

  def initialize(@model_class, @check_required)
  end

  def validate!
    model_class.columns.each do |attribute|
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

    return unless @check_required

    if !attribute[:nilable] && column.nilable?
      @required_attribute_errors << required_attribute_error(table_info.table_name, attribute)
    elsif attribute[:nilable] && !column.nilable?
      @optional_attribute_errors << optional_attribute_error(table_info.table_name, attribute)
    end
  end

  private def matching_error? : Bool
    !@missing_columns.empty? || !@optional_attribute_errors.empty? || !@required_attribute_errors.empty?
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
