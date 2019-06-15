module Avram::FormName
  macro included
    def form_name
      self.class.form_name
    end

    def self.form_name
      self.name.underscore.gsub(/_operation|save_|update_|create_/, "")
    end
  end
end
