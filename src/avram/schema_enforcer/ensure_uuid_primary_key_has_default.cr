class Avram::SchemaEnforcer::EnsureUUIDPrimaryKeyHasDefault < Avram::SchemaEnforcer::Validation
  def validate!
    return unless has_primary_key? && uuid_primary_key? && missing_column_default?

    message = <<-TEXT
    Primary key on the '#{table_name.colorize.bold}' table has the type set as uuid but does not have a default value.

    To add a default value...

      ▸ Generate a migration:

          lucky gen.migration AddDefaultTo#{Wordsmith::Inflector.pluralize(model_class.name)}PrimaryKey

      ▸ Enable a Postgres extension to generate uuids if one is not already available in the migration:

          enable_extension "uuid-ossp" # https://www.postgresql.org/docs/current/uuid-ossp.html

      ▸ Update the primary key column to have a default value in the migration:

          execute("ALTER TABLE #{table_name.colorize.bold} ALTER COLUMN #{primary_key_info.column_name.colorize.bold} SET DEFAULT uuid_generate_v4();")
    TEXT
    raise Avram::SchemaMismatchError.new(message)
  end

  def has_primary_key?
    !model_class.primary_key_name.nil?
  end

  def uuid_primary_key?
    primary_key_info.data_type == "uuid"
  end

  def missing_column_default?
    primary_key_info.column_default.nil?
  end

  def primary_key_info
    table_info.column(model_class.primary_key_name.to_s).not_nil!
  end
end
