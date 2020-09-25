require "./associations/*"

module Avram::Associations
  include HasMany
  include HasOne
  include BelongsTo

  private def lazy_load_enabled?
    Avram.settings.lazy_load_enabled
  end

  # :nodoc:
  macro __define_public_preloaded_getters(assoc_name, model, nilable)
    def {{ assoc_name.id }}! : {{ model }}{% if nilable %}?{% end %}
      get_{{ assoc_name.id }}(allow_lazy: true)
    end

    def {{ assoc_name.id }} : {{ model }}{% if nilable %}?{% end %}
      get_{{ assoc_name.id }}
    end

    @_{{ assoc_name }}_preloaded : Bool = false
    private getter? _{{ assoc_name }}_preloaded
    @[DB::Field(ignore: true)]
    private getter _preloaded_{{ assoc_name }} : {{ model }}?
  end

  # :nodoc:
  macro __define_preloaded_setter(assoc_name, model)
    # :nodoc:
    def __set_preloaded_{{ assoc_name }}(record : {{ model }}?)
      @_{{ assoc_name }}_preloaded = true
      @_preloaded_{{ assoc_name }} = record
    end
  end
end
