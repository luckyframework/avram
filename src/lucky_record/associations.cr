module LuckyRecord::Associations
  macro has_many(assoc_name, model)
    def {{ assoc_name.id }}
      {{ model }}::BaseQuery.new.{{ @type.name.underscore }}_id(id)
    end
  end

  macro belongs_to(assoc_name, model)
    field {{ assoc_name.id }}_id : Int32

    def {{ assoc_name.id }}
      {{ model }}::BaseQuery.new.find({{ assoc_name.id }}_id)
    end
  end
end
