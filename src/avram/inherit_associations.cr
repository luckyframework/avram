module Avram::InheritAssociations
  macro included
    macro inherited
      inherit_associations
    end
  end

  macro inherit_associations

    \{% if !@type.constant(:ASSOCIATIONS) %}
      ASSOCIATIONS = [] of Nil
    \{% end %}

    \{% if !@type.ancestors.first.abstract? %}
      \{% for association in @type.ancestors.first.constant :ASSOCIATIONS %}
        \{% ASSOCIATIONS << association %}
      \{% end %}
    \{% end %}

    macro inherited
      inherit_associations
    end
  end
end
