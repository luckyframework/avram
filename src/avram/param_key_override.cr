module Avram::ParamKeyOverride
  macro included
    # Override the param key used for this operation
    macro param_key(key)
      def self.param_key
        \{{ key.id.stringify }}
      end
    end
  end
end
