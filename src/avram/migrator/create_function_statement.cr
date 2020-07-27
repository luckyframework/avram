class Avram::Migrator::CreateFunctionStatement
  def initialize(@name : String, @body : String, @returns : String = "trigger")
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
      RETURNS #{@returns} AS $$
    BEGIN
      #{@body}
    END
    $$ LANGUAGE 'plpgsql';
    SQL
  end
end
