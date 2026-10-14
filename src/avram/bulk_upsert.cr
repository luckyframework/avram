class Avram::BulkUpsert(T)
  @column_types : Hash(String, String)
  @permitted_fields : Array(Symbol)

  def initialize(@records : Array(T),
                 @conflicts : Array(Symbol),
                 permitted_fields : Array(Symbol))
    set_timestamps
    @sample_record = @records.first.as(T)
    @permitted_fields = permitted_fields_for(permitted_fields)

    @column_types = T.database_table_info.columns.map do |col_info|
      {
        col_info.column_name,
        col_info.data_type,
      }
    end.to_h
  end

  def statement
    <<-SQL
    INSERT INTO #{table}(#{fields})
      (SELECT * FROM unnest(#{value_placeholders}))
      ON CONFLICT (#{conflicts}) DO UPDATE SET #{updates}
      RETURNING #{returning}
    SQL
  end

  def args
    @records.map do |record|
      permitted_attributes(record).map(&.value)
    end.transpose
  end

  private def permitted_fields_for(fields : Array(Symbol))
    fields.push(:created_at) if @sample_record.responds_to?(:created_at)
    fields.push(:updated_at) if @sample_record.responds_to?(:updated_at)
    fields.uniq!
  end

  private def permitted_attributes(record)
    record
      .attributes
      .select { |attr| @permitted_fields.includes?(attr.name) }
  end

  private def permitted_attributes
    permitted_attributes(@sample_record)
  end

  private def conflicts
    @conflicts.join(", ")
  end

  private def set_timestamps
    @records.each do |record|
      record.created_at.value ||= Time.utc if record.responds_to?(:created_at)
      record.updated_at.value ||= Time.utc if record.responds_to?(:updated_at)
    end
  end

  private def table
    @sample_record.table_name
  end

  private def updates
    (permitted_attribute_column_names - [:created_at]).compact_map do |column|
      "#{column}=EXCLUDED.#{column}"
    end.join(", ")
  end

  private def returning
    T.column_names.join(", ")
  end

  private def permitted_attribute_column_names
    permitted_attributes.map(&.name)
  end

  private def fields
    permitted_attribute_column_names.map(&.to_s).join(", ")
  end

  private def value_placeholders
    permitted_attributes.map_with_index(1) do |column, index|
      "$#{index}::#{@column_types[column.name.to_s]}[]"
    end.join(", ")
  end
end
