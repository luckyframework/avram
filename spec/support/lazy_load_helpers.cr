module LazyLoadHelpers
  private def with_lazy_load(enabled, &)
    Avram.configure do |settings|
      settings.lazy_load_enabled = enabled
    end

    yield
  ensure
    Avram.configure do |settings|
      settings.lazy_load_enabled = true
    end
  end
end
