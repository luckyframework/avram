abstract class LuckyRecord::Box
  getter form

  macro inherited
    {% unless @type.abstract? %}
      @form : {{ @type.name.gsub(/Box/, "::BaseForm").id }} = {{ @type.name.gsub(/Box/, "::BaseForm").id }}.new
    {% end %}
  end

  macro method_missing(call)
    form.{{ call.name }}.value = {{ call.args.first }}
    form
  end

  def self.save
    new.save
  end

  def save
    form.save!
  end

  def self.save_pair
    2.times { new.save }
  end
end
