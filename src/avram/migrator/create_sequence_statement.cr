# Builds an SQL statement for creating a sequence using the given name appending "_seq".
# Additional options may be provided for extra customization.
#
# ### Usage
#
# ```
# CreateSequenceStatement.new(:accounts_number, if_not_exists: true, owned_by: "accounts.number").build
# # => "CREATE SEQUENCE accounts_number_seq;"
# ```
class Avram::Migrator::CreateSequenceStatement
  private getter? if_not_exists : Bool = false

  def initialize(@name : String | Symbol, *, @if_not_exists : Bool = false, @owned_by : String = "NONE")
  end

  def build
    name = "#{@name}_seq"

    String.build do |io|
      io << "CREATE SEQUENCE "
      io << "IF NOT EXISTS " if if_not_exists?
      io << name
      io << " OWNED BY " << @owned_by << ';'
    end
  end
end
