module LazyLoadHelpers
  private def with_lazy_load(enabled)
    begin
      Avram::Database.configure do |settings|
        settings.lazy_load_enabled = enabled
      end

      yield
    ensure
      Avram::Database.configure do |settings|
        settings.lazy_load_enabled = true
      end
    end
  end
end
