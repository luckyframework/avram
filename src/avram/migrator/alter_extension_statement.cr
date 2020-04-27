class Avram::Migrator::AlterExtensionStatement
  def initialize(@name : String, @to : String? = nil)
  end

  def build
    String.build do |sql|
      sql << %{ALTER EXTENSION "#{@name}" UPDATE}
      sql << to_version if @to
      sql << ";"
    end
  end

  def to_version
    " TO '#{@to}'"
  end
end
