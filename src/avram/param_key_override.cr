module Avram::ParamKeyOverride
  macro included
    define_param_key_override

    macro inherited
      define_param_key_override
    end
  end

  macro define_param_key_override
    macro param_key(key)
      def self.param_key
        \{{ key.id.stringify }}
      end
    end
  end
end
