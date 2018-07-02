require "lucky_inflector"

print LuckyInflector::Inflector.pluralize(ARGV[0]).underscore
