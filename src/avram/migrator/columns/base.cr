abstract class Avram::Migrator::Columns::Base
  private getter name, default, references, on_delete
  private getter? nilable

  macro inherited
    @name : String
    @nilable : Bool
    @references : String?
    @on_delete : Symbol?
  end

  def set_references(@references : String, @on_delete : Symbol)
    self
  end

  def set_references(@references : Nil, @on_delete : Nil)
    self
  end

  def set_references(@references, @on_delete)
    {% raise "When setting a reference you must set the reference table and the 'on_delete' option." %}
  end

  def build_for_alter : String
    "  ADD #{column_statement}"
  end

  def build_for_create : String
    "  #{column_statement}"
  end

  private def column_statement : String
    String.build do |row|
      row << name.to_s
      row << " "
      row << column_type
      row << null_fragment
      row << default_value unless default.nil?
      row << references_clause unless references.nil?
    end
  end

  abstract def column_type : String
  abstract def formatted_default : String

  private def default_value
    " DEFAULT #{formatted_default}"
  end

  private def null_fragment
    if nilable?
      ""
    else
      " NOT NULL"
    end
  end

  private def references_clause : String
    Avram::Migrator::BuildReferenceClause.new(references, on_delete).build
  end
end
