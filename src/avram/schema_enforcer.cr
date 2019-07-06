module Avram::SchemaEnforcer
  macro setup(table_name, columns, *args, **named_args)
    include Avram::SchemaEnforcer
    def self.ensure_correct_column_mappings!
      attributes = [
        {% for attribute in columns %}
          { name: :{{attribute[:name]}}, nilable: {{ attribute[:nilable] }}, type: {{ attribute[:type] }} },
        {% end %}
      ]

      EnsureExistingTable.new(:{{table_name}}).ensure_exists!
      EnsureMatchingColumns.new(:{{table_name}}).ensure_matches! attributes
    end
  end

  class EnsureExistingTable
    @table_names : Array(String)

    def initialize(@table_name : Symbol)
      @table_names = Avram::Database.tables_with_schema(excluding: "migrations")
    end

    def ensure_exists!
      if table_missing?
        best_match = Levenshtein::Finder.find @table_name.to_s, @table_names, tolerance: 4
        message = "The table '#{@table_name}' was not found."

        if best_match
          message += " Did you mean #{best_match}?"
        end

        raise message
      end
    end

    private def table_missing?
      !@table_names.includes?(@table_name.to_s)
    end
  end

  class EnsureMatchingColumns
    @columns_map = Hash(String, Bool).new
    @missing_columns = [] of String
    @optional_attribute_errors = [] of String
    @required_attribute_errors = [] of String

    def initialize(@table_name : Symbol)
      columns = Avram::Database.table_columns(table_name)
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

        raise message.join("\n\n")
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
      message = "The table '#{table_name}' does not have a '#{missing_attribute[:name]}' column."
      best_match = Levenshtein::Finder.find missing_attribute[:name].to_s, column_names, tolerance: 4

      if best_match
        message += " Did you mean #{best_match}?"
      else
        message += " Make sure you've added it to a migration."
      end
    end

    private def optional_attribute_error(table_name, attribute)
      <<-ERROR
      '#{attribute[:name]}' is marked as nilable (#{attribute[:name]} : #{attribute[:type]}?), but the database column does not allow nils.

      Try this...

        * Mark '#{attribute[:name]}' as non-nilable in your model: #{attribute[:name]} : #{attribute[:type]}
        * Or, change the column in a migration to allow nils: make_optional :#{table_name}, :#{attribute[:name]}
      ERROR
    end

    private def required_attribute_error(table_name, attribute)
      <<-ERROR
      '#{attribute[:name]}' is marked as required (#{attribute[:name]} : #{attribute[:type]}), but the database column allows nils.

      Try this...

        * Mark '#{attribute[:name]}' as nilable in your model: #{attribute[:name]} : #{attribute[:type]}?
        * Or, change the column in a migration to be required: make_required :#{table_name}, :#{attribute[:name]}
      ERROR
    end
  end
end
