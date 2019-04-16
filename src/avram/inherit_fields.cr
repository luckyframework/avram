module Avram::InheritFields
  macro included
    macro inherited
      inherit_fields
    end
  end

  macro inherit_fields
    \{% if !@type.constant(:FIELDS) %}
      FIELDS = [] of Nil
    \{% end %}

    \{% if !@type.ancestors.first.abstract? %}
      \{% for field in @type.ancestors.first.constant :FIELDS %}
        \{% FIELDS << field %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_fields
    end
  end
end
