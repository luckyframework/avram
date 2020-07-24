module LazyLoadHelpers
  # ameba:disable Style/RedundantBegin
  private def with_lazy_load(enabled)
    begin
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
end
