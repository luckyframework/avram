require "json"

# See `Avram::ParamKeyOverride#param_key` for how the *rendering* side
# (Lucky's form helpers, e.g. `text_input`) computes the exact same
# `"key"`, `"key:field"`, and `"key[index]:field"` conventions that
# `#nested`/`#many_nested` below already know how to decode -- so a
# nested (`has_one`/`has_many`) `SaveOperation`'s fields can be rendered
# with `text_input`/etc. and parsed back out, at any nesting depth,
# without any changes needed to the decoding logic here.
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
  # association declared on the child operation needs to be represented
  # somehow under its own key within that flat, single-item `Hash`. Two
  # conventions are supported, mirroring how a real params implementation
  # (e.g. `Lucky::Params`) represents nested values, depending on whether
  # the original request was JSON or a URL-encoded/multipart HTML form:
  #
  # * a JSON request body: the nested value is JSON-encoded as a plain
  #   `String` (see `Lucky::Params#stringify_json_value`). If `@hash[key]`
  #   is a `String` that decodes as a JSON object, it's decoded into a
  #   `Hash(String, String)` and returned.
  # * a URL-encoded/multipart HTML form: the nested value's fields are
  #   submitted as their own top-level keys, prefixed with `"#{key}:"`
  #   (see `Lucky::Params#nested_form_params`). If any key in `@hash`
  #   starts with that prefix, a `Hash(String, String)` is built from
  #   those keys (with the prefix stripped) and returned.
  #
  # If neither convention matches, this falls back to the existing
  # behavior of returning all flat string values. Together, this allows
  # `has_one`/`has_many` nesting to work to any depth, for both JSON and
  # HTML form submissions.
  def nested(key : String) : Hash(String, String)
    nested_hash_from_json(key) || nested_hash_from_form_keys(key) || flat_string_params
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
  # As with `#nested` above, a further nested `has_many` association can
  # be represented either as a JSON-encoded `String` (for a JSON request)
  # or, for a URL-encoded/multipart HTML form, as a set of keys prefixed
  # with `"#{key}[index]:"` (see `Lucky::Params#many_nested_form_params`)
  # -- either way, each item is decoded into its own `Hash(String,
  # String)`, allowing a nested `SaveOperation` to declare its own
  # `has_many` association.
  def many_nested(key : String) : Array(Hash(String, String))
    many_nested_array_from_json(key) || many_nested_array_from_form_keys(key) || begin
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

  # Returns the `Hash(String, String)` built from any keys in `@hash`
  # prefixed with `"#{key}:"` (with that prefix stripped), e.g. given
  # `key` of `"reaction"`, a key of `"reaction:emoji"` contributes
  # `"emoji"` to the returned `Hash`. This is the naming convention a URL-
  # encoded/multipart HTML form (or `Lucky::Params`, see
  # `#nested_form_params`) uses to submit a `has_one` nested attribute
  # value. Returns `nil` if no key has that prefix.
  private def nested_hash_from_form_keys(key : String) : Hash(String, String)?
    prefix = "#{key}:"

    result = flat_string_params.each_with_object(Hash(String, String).new) do |(hash_key, value), hash|
      hash[hash_key.lchop(prefix)] = value if hash_key.starts_with?(prefix)
    end

    result unless result.empty?
  end

  # Returns the `Array(Hash(String, String))` built from any keys in
  # `@hash` matching `"#{key}[<index>]:<rest>"` (e.g. given `key` of
  # `"customers"`, a key of `"customers[0]:name"` contributes `"name"` to
  # the `Hash` for item `0`), grouped by `<index>` and sorted numerically
  # (so submission order doesn't affect the result). This is the naming
  # convention a URL-encoded/multipart HTML form (or `Lucky::Params`, see
  # `#many_nested_hash_params`) uses to submit a `has_many` nested
  # attribute value. Returns `nil` if no key matches.
  private def many_nested_array_from_form_keys(key : String) : Array(Hash(String, String))?
    matcher = /^#{Regex.escape(key)}\[(?<index>\d+)\]:(?<rest>.+)$/
    grouped = Hash(Int32, Hash(String, String)).new { |hash, index| hash[index] = Hash(String, String).new }

    flat_string_params.each do |hash_key, value|
      hash_key.match(matcher).try do |match|
        grouped[match["index"].to_i][match["rest"]] = value
      end
    end

    return if grouped.empty?

    grouped.keys.sort!.map { |index| grouped[index] }
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
