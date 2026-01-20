class Avram::Migrator::CreateFunctionStatement
  enum Behavior
    IMMUTABLE
    STABLE
    VOLATILE
  end

  def initialize(@name : String, @body : String, @returns : String = "trigger", @language : String = "plpgsql", @behavior : Behavior = Behavior::VOLATILE)
  end

  def function_name
    if @name.ends_with?(')')
      @name
    else
      "#{@name}()"
    end
  end

  def build
    <<-SQL
    CREATE OR REPLACE FUNCTION #{function_name}
      RETURNS #{@returns}
    AS $$
      #{@body}
    $$
    LANGUAGE #{@language}
    #{@behavior};
    SQL
  end
end
