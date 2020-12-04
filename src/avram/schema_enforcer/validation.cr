abstract class Avram::SchemaEnforcer::Validation
  private getter model_class : Avram::Model.class

  def initialize(@model_class)
  end

  abstract def validate!

  private def table_name
    model_class.table_name.to_s
  end

  private def database_info
    model_class.database.database_info
  end

  private def table_info
    model_class.database_table_info.not_nil!
  end
end
