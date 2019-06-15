module Avram::InheritAttributess
  macro included
    macro inherited
      inherit_attributes
    end
  end

  macro inherit_attributes
    \{% if !@type.constant(:ATTRIBUTES) %}
      ATTRIBUTES = [] of Nil
    \{% end %}

    \{% if !@type.ancestors.first.abstract? %}
      \{% for attribute in @type.ancestors.first.constant :ATTRIBUTES %}
        \{% ATTRIBUTES << attribute %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_attributes
    end
  end
end
