module Avram::ParamKeyOverride
  macro param_key(key)
    def self.form_name
      {{ key.id.stringify }}
    end
  end
end
