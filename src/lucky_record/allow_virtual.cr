module LuckyRecord::AllowVirtual
  macro allow_virtual(name)
    @_{{ name }} : LuckyRecord::Field(String?)?

    def {{ name }}
      LuckyRecord::AllowedField.new(_{{ name }})
    end

    private def _{{ name }}
      @_{{ name }} ||= LuckyRecord::Field(String?).new(
        name: :{{ name }},
        param: {{ name }}_param,
        value: {{ name }}_param,
        form_name: form_name
      )
    end

    private def {{ name }}_param
      params.nested!(form_name)["{{ name }}"]?
    end
  end
end
