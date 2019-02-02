module Avram::Callbacks
  macro before_save(method)
    def before_save
      {% if @type.methods.map(&.name).includes?(:before_save.id) %}
        previous_def
      {% end %}

      {{ method.id }}
    end
  end

  macro after_save(method)
    def after_save(object)
      {% if @type.methods.map(&.name).includes?(:after_save.id) %}
        previous_def
      {% end %}

      {{ method.id }}(object)
    end
  end

  macro before_create(method)
    def before_create
      {% if @type.methods.map(&.name).includes?(:before_create.id) %}
        previous_def
      {% end %}

      {{ method.id }}
    end
  end

  macro after_create(method)
    def after_create(object)
      {% if @type.methods.map(&.name).includes?(:after_create.id) %}
        previous_def
      {% end %}

      {{ method.id }}(object)
    end
  end

  macro before_update(method)
    def before_update
      {% if @type.methods.map(&.name).includes?(:before_update.id) %}
        previous_def
      {% end %}

      {{ method.id }}
    end
  end

  macro after_update(method)
    def after_update(object)
      {% if @type.methods.map(&.name).includes?(:after_update.id) %}
        previous_def
      {% end %}

      {{ method.id }}(object)
    end
  end
end
