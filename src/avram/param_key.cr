module Avram::ParamKey
  macro included
    # Override the param key used for this operation
    macro param_key(key)
      def self.param_key
        \{{ key.id.stringify }}
      end
    end

    def self.param_key
      name.underscore.gsub(/_operation|save_|update_|create_/, "")
    end
  end
end
