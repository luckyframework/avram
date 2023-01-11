class Avram::SchemaEnforcer::EnsureExistingTable < Avram::SchemaEnforcer::Validation
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

  private def table_missing? : Bool
    !model_class.database_table_info
  end
end
