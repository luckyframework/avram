abstract class Avram::Box
  getter form

  macro inherited
    {% unless @type.abstract? %}
      {% form = @type.name.gsub(/Box/, "::BaseForm").id %}
      @form : {{ form }} = {{ form }}.new
      setup_field_shortcuts({{ form }})
    {% end %}
  end

  macro setup_field_shortcuts(form)
    {% for field in form.resolve.constant(:FIELDS) %}
      def {{ field[:name] }}(value : {{ field[:type] }}{% if field[:nilable] %}?{% end %})
        form.{{ field[:name] }}.value = value
        self
      end
    {% end %}
  end

  def self.save
    {% raise "'Box.save' has been renamed to 'Box.create' to match 'Form.create'" %}
  end

  def self.create
    new.create
  end

  def self.create
    yield(new).create
  end

  def create
    form.save!
  end

  def self.create_pair
    2.times { new.create }
  end
end
