# This class is used in various places
# where the question of "Did I not pass in anything or did I pass in nil?"
# needs to be answered.
# :nodoc:
class Avram::Nothing
end

# Use this value when you want to ignore updating a column
# in a SaveOperation instead of setting the column value to `nil`.
#
# ```
# # Set value to x.value or ignore it if x.value is nil
# SaveThing.create!(
#   value: x.value || IGNORE
# )
# ```
IGNORE = Avram::Nothing.new
