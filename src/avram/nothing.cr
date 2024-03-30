# This class is used in various places
# where the question of "Did I not pass in anything or did I pass in nil?"
# needs to be answered.
# :nodoc:
class Avram::Nothing
end

# Use this value when you want to ignore updating a column
# in a SaveOperation, for example.
# ```
# # Sets value to x.value or ignores it if x.value is nil
# SaveThing.create!(
#   value: x.value || Undefined
# )
Undefined = Avram::Nothing.new
