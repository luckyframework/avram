abstract class Avram::Migrator::Columns::Base
  private getter name, default, references, on_delete
  private getter? nilable

  macro inherited
    @name : String
    @array : Bool?
    @nilable : Bool?
    @references : String?
    @on_delete : Symbol?
  end

  def initialize(@name)
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

  def array!
    @array = true
    self
  end

  def build_change_type_statement(table_name : TableName) : String
    "ALTER TABLE #{table_name} ALTER COLUMN #{name} SET DATA TYPE #{column_type};"
  end

  def build_change_default_statement(table_name : TableName) : String
    "ALTER TABLE ONLY #{table_name} ALTER COLUMN #{name} SET#{default_fragment};"
  end

  def build_add_statement_for_alter : String
    "  ADD " + build_add_statement
  end

  def build_add_statement_for_create : String
    "  " + build_add_statement
  end

  def as_array_type : String
    @array ? "[]" : ""
  end

  private def build_add_statement : String
    String.build do |row|
      row << name.to_s
      row << " "
      row << column_type + as_array_type
      row << null_fragment
      row << default_fragment unless default.nil?
      row << references_fragment unless references.nil?
    end
  end

  abstract def column_type : String

  private def default_fragment
    " DEFAULT #{self.class.prepare_value_for_database(default)}"
  end

  def self.prepare_value_for_database(value)
    escape_literal(value.to_s)
  end

  def self.prepare_value_for_database(value : Array)
    escape_literal(PQ::Param.encode_array(value))
  end

  def self.escape_literal(value)
    PG::EscapeHelper.escape_literal(value)
  end

  private def null_fragment
    if nilable?
      ""
    else
      " NOT NULL"
    end
  end

  private def references_fragment : String
    Avram::Migrator::BuildReferenceFragment.new(references, on_delete).build
  end
end
