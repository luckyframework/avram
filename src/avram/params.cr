require "json"

class Avram::Params
  include Avram::Paramable

  @hash : Hash(String, Array(String) | String) |  \
    Hash(String, Array(String)) |  \
    Hash(String, String)

  def initialize
    @hash = {} of String => String
  end

  def initialize(@hash)
  end

  def nested?(key : String) : Hash(String, String)
    nested(key)
  end

  # Returns the nested params for `key`.
  #
  # When a `has_many` nested `SaveOperation` wraps each of its items in a
  # new `Avram::Params`, any further nested (`has_one`/`has_many`)
  # association declared on the child operation is JSON-encoded as a
  # plain `String` under its own key (mirroring how a real params
  # implementation, e.g. `Lucky::Params`, stringifies non-scalar JSON
  # values -- see `#many_nested` below). To support that, if `@hash[key]`
  # is a `String` that decodes as a JSON object, it's decoded into a
  # `Hash(String, String)` and returned; otherwise, this falls back to
  # the existing behavior of returning all flat string values, allowing
  # `has_one`/`has_many` nesting to work to any depth.
  def nested(key : String) : Hash(String, String)
    nested_hash_from_json(key) || flat_string_params
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    nested_arrays(key)
  end

  def nested_arrays(key : String) : Hash(String, Array(String))
    Hash(String, Array(String)).new.tap do |params|
      @hash.each do |_key, _value|
        params[_key] = _value if _value.is_a?(Array)
      end
    end
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    many_nested(key)
  end

  # `Avram::Params` stores a single, flat record, so there's no real
  # concept of "many" nested records here. To avoid building a phantom,
  # empty nested record when no params were given at all (e.g. the
  # default `Avram::Params.new`), this returns an empty `Array` unless
  # there is actual data present, in which case it's returned as a single
  # item for convenience (e.g. when manually testing a `has_many` nested
  # `SaveOperation` with a single record's worth of params).
  #
  # If `@hash[key]` is a `String` that decodes as a JSON array of
  # objects (see `#nested` above), each object is decoded into its own
  # `Hash(String, String)` instead, allowing a nested `SaveOperation` to
  # declare its own `has_many` association.
  def many_nested(key : String) : Array(Hash(String, String))
    many_nested_array_from_json(key) || begin
      data = flat_string_params
      data.empty? ? [] of Hash(String, String) : [data]
    end
  end

  def get?(key : String)
    @hash[key]?.try { |value| value if value.is_a?(String) }
  end

  def get(key : String)
    get?(key).not_nil! # ameba:disable Lint/NotNil
  end

  def get_all?(key : String)
    @hash[key]?.try { |value| value if value.is_a?(Array) }
  end

  def get_all(key : String)
    get_all?(key).not_nil! # ameba:disable Lint/NotNil
  end

  def nested_file?(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested_file(key : String) : Hash(String, String)
    nested(key)
  end

  def get_all_files(key : String)
    get_all(key)
  end

  private def flat_string_params : Hash(String, String)
    Hash(String, String).new.tap do |params|
      @hash.each do |_key, _value|
        params[_key] = _value if _value.is_a?(String)
      end
    end
  end

  # Returns the `Hash(String, String)` decoded from `@hash[key]` if it's a
  # `String` holding a JSON object (e.g. `{"body":"Hi"}`), or `nil` if
  # there's no value for `key`, or it isn't JSON-object shaped.
  private def nested_hash_from_json(key : String) : Hash(String, String)?
    json_hash_at(key).try { |json_hash| stringify_json_hash(json_hash) }
  end

  # Returns the `Array(Hash(String, String))` decoded from `@hash[key]`
  # if it's a `String` holding a JSON array of objects (e.g.
  # `[{"body":"Hi"}]`), or `nil` if there's no value for `key`, it isn't a
  # JSON array, or any element of the array isn't a JSON object.
  private def many_nested_array_from_json(key : String) : Array(Hash(String, String))?
    json_any_at(key).try(&.as_a?).try do |json_array|
      return nil unless json_array.all?(&.as_h?)

      json_array.map { |json_item| stringify_json_hash(json_item.as_h) }
    end
  end

  private def json_hash_at(key : String) : Hash(String, JSON::Any)?
    json_any_at(key).try(&.as_h?)
  end

  private def json_any_at(key : String) : JSON::Any?
    value = @hash[key]?
    return unless value.is_a?(String)

    JSON.parse(value)
  rescue JSON::ParseException
    nil
  end

  private def stringify_json_hash(json_hash : Hash(String, JSON::Any)) : Hash(String, String)
    json_hash.each_with_object(Hash(String, String).new) do |(json_key, json_value), result|
      result[json_key] = json_value.as_s? || json_value.to_json
    end
  end
end
