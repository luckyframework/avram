class Avram::Migrator::BuildReferenceFragment
  private getter references, on_delete

  @references : TableName?
  @on_delete : Symbol?

  def initialize(@references, @on_delete)
  end

  def build
    if on_delete == :do_nothing
      " REFERENCES #{references}"
    else
      " REFERENCES #{references}" + " ON DELETE " + on_delete_sql
    end
  end

  private def on_delete_sql : String
    case on_delete
    when :nullify
      "SET NULL"
    when :cascade, :restrict
      on_delete.to_s.upcase
    else
      raise "on_delete: :#{on_delete} is not supported. Please use :do_nothing, :cascade, :restrict, or :nullify"
    end
  end
end
