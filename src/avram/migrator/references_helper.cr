module Avram::Migrator::ReferencesHelper
  def references(table_name : String | Symbol | Nil, on_delete = :do_nothing)
    if table_name.nil?
      ""
    elsif on_delete == :do_nothing
      " REFERENCES #{table_name}"
    else
      " REFERENCES #{table_name}" + " ON DELETE " + on_delete_sql(on_delete)
    end
  end

  private def on_delete_sql(on_delete : Symbol?) : String
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
