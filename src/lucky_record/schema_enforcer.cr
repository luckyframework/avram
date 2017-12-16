module LuckyRecord::SchemaEnforcer
  macro add_schema_enforcer_methods_for(table_name, fields)
    def ensure_correct_field_mappings!
      fields = [
        {% for field in fields %}
          { name: :{{field[:name]}}, nilable: {{ field[:nilable] }}, type: {{ field[:type] }} },
        {% end %}
      ]

      EnsureExistingTable.new(:{{table_name}}).ensure_exists!
      EnsureMatchingColumns.new(:{{table_name}}).ensure_matches! fields
    end
  end

  class EnsureExistingTable
    @table_names : Array(String)

    def initialize(@table_name : Symbol)
      @table_names = LuckyRecord::Repo.tables_with_schema(excluding: "migrations")
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
    @optional_field_errors = [] of String
    @required_field_errors = [] of String

    def initialize(@table_name : Symbol)
      columns = LuckyRecord::Repo.table_columns(table_name)
      columns.each do |column|
        @columns_map[column.name] = column.nilable
      end
    end

    def ensure_matches!(fields)
      fields.each do |field|
        check_column_matches field
      end

      if matching_error?
        message = @missing_columns + @optional_field_errors + @required_field_errors

        raise message.join("\n\n")
      end
    end

    private def check_column_matches(field)
      unless @columns_map.has_key? field[:name].to_s
        @missing_columns << missing_field_error(@table_name, @columns_map.keys, field)
        return
      end

      if !field[:nilable] && @columns_map[field[:name].to_s]
        @required_field_errors << required_field_error(@table_name, field)
      elsif field[:nilable] && !@columns_map[field[:name].to_s]
        @optional_field_errors << optional_field_error(@table_name, field)
      end
    end

    private def matching_error?
      @missing_columns.any? || @optional_field_errors.any? || @required_field_errors.any?
    end

    private def missing_field_error(table_name, column_names, missing_field)
      message = "The table '#{table_name}' does not have a '#{missing_field[:name]}' column."
      best_match = Levenshtein::Finder.find missing_field[:name].to_s, column_names, tolerance: 4

      if best_match
        message += " Did you mean #{best_match}?"
      else
        message += " Make sure you've added it to a migration."
      end
    end

    private def optional_field_error(table_name, field)
      <<-ERROR
      '#{field[:name]}' is marked as nilable (#{field[:name]} : #{field[:type]}?), but the database column does not allow nils.

      Try this...

        * Mark '#{field[:name]}' as non-nilable in your model: #{field[:name]} : #{field[:type]}
        * Or, change the column in a migration to allow nils: make_optional :#{table_name}, :#{field[:name]}
      ERROR
    end

    private def required_field_error(table_name, field)
      <<-ERROR
      '#{field[:name]}' is marked as required (#{field[:name]} : #{field[:type]}), but the database column allows nils.

      Try this...

        * Mark '#{field[:name]}' as nilable in your model: #{field[:name]} : #{field[:type]}?
        * Or, change the column in a migration to be required: make_required :#{table_name}, :#{field[:name]}
      ERROR
    end
  end
end
