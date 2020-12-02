abstract class Avram::SchemaEnforcer::Validation
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
