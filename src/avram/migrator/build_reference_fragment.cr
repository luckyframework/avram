class Avram::Migrator::BuildReferenceFragment
  private getter references, on_delete

  @references : TableName?
  @on_delete : Symbol?

  def initialize(@references, @on_delete)
  end

  def build
    String.build { |io| build(io) }
  end

  def build(io : IO)
    if on_delete == :do_nothing
      io << " REFERENCES "
      io << references
    else
      io << " REFERENCES "
      io << references
      io << " ON DELETE "
      io << on_delete_sql
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
