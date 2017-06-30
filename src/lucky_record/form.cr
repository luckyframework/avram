require "./validations"

abstract class LuckyRecord::Form(T)
  include LuckyRecord::Validations

  macro inherited
    @valid : Bool = true
    @performed : Bool = false

    @@allowed_param_keys = [] of String
    @@schema_class = T

    def form_name
      {{ @type.name.underscore.stringify }}
    end
  end

  property? performed : Bool = false
  getter :record

  @record : T?
  @params : LuckyRecord::Paramable

  abstract def table_name
  abstract def fields
  abstract def call
  abstract def form_name

  macro add_fields(fields)
    private def extract_changes_from_params
      allowed_params.each do |key, value|
        {% for field in fields %}
          set_{{ field[:name] }}_from_param value if key == {{ field[:name].stringify }}
        {% end %}
      end
    end

    {% for field in fields %}
      @_{{ field[:name] }} : LuckyRecord::Field({{ field[:type] }}::BaseType?)?

      def _{{ field[:name] }}
        @_{{ field[:name] }} ||= LuckyRecord::Field({{ field[:type] }}::BaseType?).new(
          name: :{{ field[:name].id }},
          param: allowed_params["{{ field[:name] }}"]?,
          value: @record.try(&.{{ field[:name] }}),
          form_name: form_name)
      end

      def allowed_params
        @params.nested!(form_name).select(@@allowed_param_keys)
      end

      def set_{{ field[:name] }}_from_param(value)
        cast_result = {{ field[:type] }}.cast(value)
        if cast_result.is_a? LuckyRecord::Type::SuccessfulCast
          _{{ field[:name] }}.value = cast_result.value
        else
          _{{ field[:name] }}.add_error "is invalid"
        end
      end
    {% end %}

    def fields
      [
        {% for field in fields %}
          _{{ field[:name] }},
        {% end %}
      ]
    end
  end

  def initialize(params : Hash(String, String) | LuckyRecord::Paramable)
    @params = ensure_paramable(params)
    extract_changes_from_params
  end

  def initialize(**params)
    @params = named_tuple_to_params(params)
    extract_changes_from_params
  end

  def initialize(@record, params : Hash(String, String) | LuckyRecord::Paramable)
    @params = ensure_paramable(params)
    extract_changes_from_params
  end

  def initialize(@record, **params)
    @params = named_tuple_to_params(params)
    extract_changes_from_params
  end

  private def named_tuple_to_params(named_tuple)
    params_with_stringified_keys = {} of String => String
    named_tuple.each do |key, value|
      params_with_stringified_keys[key.to_s] = value
    end
    LuckyRecord::Params.new params_with_stringified_keys
  end

  private def ensure_paramable(params)
    if params.is_a? LuckyRecord::Paramable
      params
    else
      LuckyRecord::Params.new(params)
    end
  end

  def valid? : Bool
    call
    # TODO: run_auto_generated_validations
    fields.all? &.valid?
  end

  def self.save(params)
    form = new(params)
    if form.save
      yield form, form.record
    else
      yield form, nil
    end
  end

  def self.update(record, with params)
    form = new(record, params)
    if form.save
      yield form, form.record.not_nil!
    else
      yield form, form.record.not_nil!
    end
  end

  def save_succeeded?
    !save_failed?
  end

  def save_failed?
    !valid? && performed?
  end

  macro allow(*field_names)
    {% for field_name in field_names %}
      def {{ field_name.id }}
        _{{ field_name.id }}
      end

      @@allowed_param_keys << "{{ field_name.id }}"
    {% end %}
  end

  def changes
    _changes = {} of Symbol => String?
    fields.each do |field|
      if field.changed?
        _changes[field.name] = field.value.to_s
      end
    end
    _changes
  end

  def save : Bool
    @performed = true

    record_id = @record.try &.id
    if record_id
      update record_id
    else
      insert
    end
  end

  private def insert
    self._created_at.value = Time.now
    self._updated_at.value = Time.now
    if valid?
      @record = LuckyRecord::Repo.run do |db|
        db.query insert_sql.statement, insert_sql.args do |rs|
          @@schema_class.from_rs(rs)
        end.first
      end

      true
    else
      false
    end
  end

  private def update(id)
    if valid?
      @record = LuckyRecord::Repo.run do |db|
        db.query update_query(id).statement_for_update(changes), update_query(id).args_for_update(changes) do |rs|
          @@schema_class.from_rs(rs)
        end.first
      end
      true
    else
      false
    end
  end

  private def update_query(id)
    LuckyRecord::QueryBuilder
      .new(table_name)
      .where(LuckyRecord::Where::Equal.new(:id, id.to_s))
  end

  private def insert_sql
    LuckyRecord::Insert.new(table_name, changes)
  end
end
