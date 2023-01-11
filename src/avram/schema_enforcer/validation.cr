abstract class Avram::SchemaEnforcer::Validation
  private getter model_class : Avram::Model.class

  def initialize(@model_class)
  end

  abstract def validate!

  private def table_name : String
    model_class.table_name.to_s
  end

  private def database_info : Avram::Database::DatabaseInfo
    model_class.database.database_info
  end

  private def table_info : Avram::Database::TableInfo
    model_class.database_table_info.as(Avram::Database::TableInfo)
  end
end
