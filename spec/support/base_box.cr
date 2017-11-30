abstract class BaseBox
  forward_missing_to @record
  getter form

  def initialize
    @record = build_model
  end

  macro inherited
    @record : {{@type.name.gsub(/Box/, "").id}}?
    form {{ @type.name.gsub(/Box/, "::BaseForm").id }}
  end

  def self.build
    new.build
  end

  def build
    @record.not_nil!
  end

  def build_pair
    [@record, @record]
  end

  macro form(form_class)
    @form = {{ form_class }}.new
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
    new.save
    new.save
  end
end
