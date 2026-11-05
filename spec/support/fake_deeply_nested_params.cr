# A generic, reusable fake `Avram::Paramable` implementation for testing
# nested (`has_one`) and many-nested (`has_many`) `SaveOperation`s, keyed
# by the same param key each level's `SaveOperation` looks itself up by
# (for `has_one`, that's the child model's underscored name; for
# `has_many`, that's the declared association name -- see
# `Avram::NestedSaveOperation`).
#
# Values passed to `many_nested_data` may themselves include a key whose
# value is either a JSON-encoded object/array `String`, or a set of keys
# prefixed with `"{key}:"`/`"{key}[index]:"`, mirroring how a real params
# implementation (e.g. `Lucky::Params`) represents nested values for a
# JSON request or a URL-encoded/multipart HTML form, respectively -- this
# lets a nested `has_many` `SaveOperation` declare its own further
# `has_one`/`has_many` nesting (see `Avram::Params#nested`/`#many_nested`).
class FakeDeeplyNestedParams
  include Avram::Paramable

  def initialize(
    @nested_data = {} of String => Hash(String, String),
    @many_nested_data = {} of String => Array(Hash(String, String)),
  )
  end

  def nested(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested?(key : String) : Hash(String, String)
    @nested_data[key]? || ({} of String => String)
  end

  def nested_arrays(key : String) : Hash(String, Array(String))
    nested_arrays?(key)
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    {} of String => Array(String)
  end

  def nested_file(key : String) : Hash(String, String)
    nested(key)
  end

  def nested_file?(key : String) : Hash(String, String)
    nested?(key)
  end

  def many_nested(key : String) : Array(Hash(String, String))
    many_nested?(key)
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    @many_nested_data[key]? || ([] of Hash(String, String))
  end

  def get(key : String)
    get?(key)
  end

  def get?(key : String)
    nil
  end

  def get_all(key : String)
    get_all?(key)
  end

  def get_all?(key : String)
    nil
  end
end
