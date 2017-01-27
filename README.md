# LuckyRecord

This is a WIP. Most of the code is not yet written, this is just a guide for how
I think things will look

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  lucky_record:
    github: luckyframework/record
```

## Install

```crystal
require "lucky_record"
```

## Making a schema

```crystal
class Task < LuckyRecord::Schema
  # Table is inferred from model name
  # timestamps and id are automatically added
  field title : String
  field description : String = "default description"
  field completed_at : Time? # If use `?` then the field will be nullable
end
```

## Adding associations

Add a Comment that belongs to a Task

```crystal
class Comment < LuckyRecord::Schema
  field body : String
  field rating : Int32 = 0
  belongs_to Task
end
```

Add the comments to the Task schema

```crystal
class Task < LuckyRecord::Schema
  # fields omitted for brevity
  has_many Comment
end
```

## Basic queries

When you create a schema, some abstract base classes are also created. One of
these is `#{schema name}::BaseRows`

```crystal
# Inherit from the automatically generated Task::BaseRows class
class TaskRows < Task::BaseRows
end
```

You can now make queries like this

```crystal
# Get all
TasksRows.all

# Filter things down by field
TasksRows.all.where_title("My Task Title")

# You can chain methods
TasksRows.all.where_title("My Task Title").where_body("Very important")

# You can do more advanced queries using blocks
TaskRows.all.where &.completed_at > 5.days.ago
```

## Querying associations

```crystal
TaskRows.all.where_comments &.rating > 4

# It's often best to extract queries to the row object
class TaskRows < Task::BaseRows
  def highly_rated
    where_comments &.rating > 4
  end
end

TaskRows.all.highly_rated
```

## Query scopes

You can add query scopes by adding instance methods to your Rows objects

```crystal
class TaskRows < Task::BaseRows
  def completed
    where &.completed_at != nil
  end
end

TaskRows.all.completed

# These are chainable
TaskRows.all.completed.where_title("Very important task")
```

## Preloading associations

Avoid N+1 by preloading (eager loading) associations

```crystal
TaskRows.all.preload_comments
```

You can also load deeply nested associations

Let's say we add a `belongs_to User` on the `Task` schema, and that a `Task`
also `has_many Tag`. We can preload these associations in one go

```crystal
# This will preload the tasks tags and comments, and will also load the comment's user.
TaskRows.all.preload_tags.preload_comments &.preload_user
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/luckyframework/lucky_record/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [paulcsmith](https://github.com/paulcsmith) Paul Smith - creator, maintainer
