abstract class LuckyRecord::Box
  getter form

  macro inherited
    {% unless @type.abstract? %}
      @form : {{ @type.name.gsub(/Box/, "::BaseForm").id }} = {{ @type.name.gsub(/Box/, "::BaseForm").id }}.new
    {% end %}
  end

  macro method_missing(call)
    form.{{ call.name }}.value = {{ call.args.first }}
    self
  end

  def save
    self.class.save
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
