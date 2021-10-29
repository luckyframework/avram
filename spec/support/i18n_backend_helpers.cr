module I18nBackendHelpers
  private def with_i18n_backend(backend : Avram::I18nBackend)
    Avram.configure do |settings|
      settings.i18n_backend = backend
    end

    yield
  ensure
    Avram.configure do |settings|
      settings.i18n_backend = Avram::I18n.new
    end
  end
end
