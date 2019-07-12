require "wordsmith"

print Wordsmith::Inflector.pluralize(ARGV[0]).gsub("::", "").underscore
