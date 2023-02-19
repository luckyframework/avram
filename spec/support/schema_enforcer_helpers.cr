module SchemaEnforcerHelpers
  private def expect_schema_mismatch(message : String, &)
    original_colorize_setting = Colorize.enabled?
    Colorize.enabled = false
    expect_raises Avram::SchemaMismatchError, message do
      yield
    end
  ensure
    Colorize.enabled = !!original_colorize_setting
  end
end
