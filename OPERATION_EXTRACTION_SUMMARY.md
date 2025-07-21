# Operation Extraction Summary

This document summarizes the extraction of a base operation class from Avram to Lucky framework.

## What was done

1. **Created Lucky::BaseOperation** - A lightweight abstract base class that provides:
   - The core operation pattern (run/run! methods)
   - Before/after hooks (before_run, after_run)
   - Basic parameter handling via Lucky::Paramable interface
   - Abstract methods for validation and attributes

2. **Created Lucky::Paramable** - A generic interface for parameter handling that both Lucky and Avram can implement

3. **Created Lucky::BasicParams** - A simple implementation of Lucky::Paramable for basic use cases

4. **Updated Avram::Operation** to inherit from Lucky::BaseOperation while maintaining backward compatibility

## Files created in src/lucky/

- `src/lucky/base_operation.cr` - The abstract base operation class
- `src/lucky/paramable.cr` - The paramable interface
- `src/lucky/basic_params.cr` - Basic params implementation
- `src/lucky/failed_operation_error.cr` - Exception for failed operations

## Changes to Avram

- `src/avram/operation.cr` - Now inherits from Lucky::BaseOperation
- `src/avram/paramable.cr` - Now includes Lucky::Paramable
- `src/avram/operation_adapters.cr` - Provides backward compatibility

## Benefits

1. **Separation of concerns** - Database-specific logic stays in Avram, generic operation pattern moves to Lucky
2. **Reusability** - Lucky applications can now use operations without Avram dependencies
3. **Backward compatibility** - Existing Avram operations continue to work unchanged
4. **Clean architecture** - The base operation is minimal and focused on the core pattern

## Usage in Lucky (without Avram)

```crystal
class MyOperation < Lucky::BaseOperation
  def run
    # Operation logic here
  end

  def valid? : Bool
    # Validation logic
    true
  end

  def attributes
    [] of Lucky::Operation::Attribute
  end

  def custom_errors
    {} of Symbol => Array(String)
  end
end

# Use it
MyOperation.run do |operation, result|
  # Handle result
end
```

## Next steps for Lucky integration

The Lucky team will need to:
1. Move these files to the Lucky shard
2. Add proper module structure for attributes, validations, etc. if needed
3. Document the new operation pattern
4. Consider creating Lucky-specific helper modules similar to Avram's

## Note

The current implementation is minimal by design. It provides just the core operation pattern without prescribing how attributes, validations, or errors should be implemented. This gives Lucky the flexibility to implement these features in a way that best fits the framework.