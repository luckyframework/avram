require "wordsmith"

print Wordsmith::Inflector.pluralize(ARGV[0]).underscore
