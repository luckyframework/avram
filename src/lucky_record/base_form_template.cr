class LuckyRecord::BaseFormTemplate
  macro setup(model_type, fields, table_name)
    class BaseForm < LuckyRecord::Form({{ model_type }})
      def table_name
        {{ table_name }}
      end

      def call
        # TODO add default validate_required for non-nilable fields
      end

      add_fields({{ fields }})
    end
  end
end
