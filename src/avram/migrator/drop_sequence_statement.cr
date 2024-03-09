# Builds an SQL statement for dropping a sequence using the given name.
#
# ### Usage
#
# ```
# DropSequenceStatement.new(:accounts_number, if_not_exists: true, owned_by: "accounts.number").build
# # => "CREATE SEQUENCE accounts_number_seq;"
# ```
class Avram::Migrator::DropSequenceStatement
  def initialize(@name : String | Symbol)
  end

  def build
    name = "#{@name}_seq"

    String.build do |io|
      io << "DROP SEQUENCE IF EXISTS "
      io << name
      io << ';'
    end
  end
end
