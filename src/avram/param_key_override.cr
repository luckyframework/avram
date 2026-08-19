module Avram::ParamKeyOverride
  macro included
    define_param_key_override

    macro inherited
      define_param_key_override
    end
  end

  macro define_param_key_override
    macro param_key(key)
      def self.param_key : String
        \{{ key.id.stringify }}
      end
    end
  end

  @_param_key : String?

  # The prefix any of this instance's *own* nested (`has_one`/`has_many`)
  # operations should build their own `#param_key` on top of.
  #
  # This is an empty `String` by default (the root of a params tree has no
  # prefix). It's only ever set by `Avram::NestedSaveOperation`'s
  # `has_one`/`has_many` macros, at construction time, to whatever key was
  # computed for that nested child operation -- see
  # `Avram::NestedSaveOperation` for the exact propagation rules.
  #
  # :nodoc:
  property nested_param_key_prefix : String = ""

  # :nodoc:
  #
  # Overrides this instance's own `#param_key`/`#nested_param_key_prefix`.
  # Must run *before* any of this instance's attributes are built (see
  # `Avram::Attribute#permitted`/`#render_param_key`), since each
  # attribute's render key is computed and memoized the first time it's
  # touched -- that's why `Avram::NeedyInitializerAndSaveMethods`'
  # generated `initialize` methods call this before `set_attributes`.
  #
  # Only ever called by `Avram::NestedSaveOperation`'s `has_one`/
  # `has_many` macros, via the `_nested_param_key`/
  # `_nested_param_key_prefix` constructor arguments -- never set directly
  # by application code.
  def apply_nested_param_key_override(_nested_param_key : String?, _nested_param_key_prefix : String?) : Nil
    @_param_key = _nested_param_key
    self.nested_param_key_prefix = _nested_param_key_prefix unless _nested_param_key_prefix.nil?
  end

  # The key this operation instance's own attributes should be rendered
  # (`name=`/`id=`, via the Lucky form helpers) and extracted under.
  #
  # This is identical to the class-level `self.class.param_key` (and, for
  # any operation that isn't a nested `has_one`/`has_many` child, that's
  # exactly what it stays). It's only overridden on a nested child
  # operation built by `Avram::NestedSaveOperation`'s `has_one`/`has_many`
  # macros, so that fields rendered on the child carry a fully-qualified
  # key (e.g. `"comments[0]"`, or `"comments[0]:reaction"`) that
  # `Avram::Params`/`Lucky::Params` already know how to decode back on
  # submission -- see `Avram::NestedSaveOperation`.
  def param_key : String
    @_param_key || self.class.param_key
  end
end
