class Avram::PreparedStatementGenerator
  @prepared_statement_placeholder : Int32 = 0

  def next
    @prepared_statement_placeholder += 1
    "$#{@prepared_statement_placeholder}"
  end
end
