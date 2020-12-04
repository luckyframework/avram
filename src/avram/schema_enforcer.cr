require "./schema_enforcer/validation"
require "./schema_enforcer/*"

module Avram::SchemaEnforcer
  ALL_MODELS     = [] of Avram::Model.class
  MODELS_TO_SKIP = [] of String # Stringified class name

  macro setup(type, *args, **named_args)
    class_getter schema_enforcer_validations = [] of Avram::SchemaEnforcer::Validation

    def self.ensure_correct_column_mappings!
      return if Avram::SchemaEnforcer::MODELS_TO_SKIP.includes?(self.name)

      schema_enforcer_validations.each(&.validate!)
    end

    {% if !type.resolve.abstract? %}
      {% Avram::SchemaEnforcer::ALL_MODELS << type %}
    {% end %}
  end

  def self.ensure_correct_column_mappings!
    {% if !ALL_MODELS.empty? %}
      ALL_MODELS.each do |model|
        model.ensure_correct_column_mappings!
      end
    {% end %}
  end

  macro skip_schema_enforcer
    {% Avram::SchemaEnforcer::MODELS_TO_SKIP << @type.stringify %}
  end
end
