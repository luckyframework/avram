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

## Inserting and updating schemas with Forms

Another base class is created for you when you create a schema `#{schema name}::BaseForm`.

```crystal
class TaskForm < Task::BaseForm
end
```

To make changes to the model we first need to allow them

```crystal
class TaskForm < Task::BaseForm
  allow :title, :description
end
```

Now let's try some stuff with forms

```crystal
form = TaskForm.new(title: "Clean room", description: nil)
form.valid? # returns false
form.insert # returns false and does not insert the task

form.description = "Description"
form.valid? # returns true
form.insert # returns true and inserts the task. Or maybe return the Task || FailedInsert
```

As you can see there are some default validations. The `Task::BaseForm` has
added some `validate_required` validations because those fields are no nullable
in our schema. We can leave of `completed_at` and it is still valid because we
mark it as nullable in the schema with `?` in the type.

Let's make our form do a bit more

```crystal
class TaskForm < Task::BaseForm
  allow :title, :description

  def call
    validate_length_of :title, min: 10
    make_title_pretty
  end

  private def make_title_pretty
    title.capitalize
  end
end

# Now let's see what we get
form = TaskForm.new(title: "short", description: "ok")
form.valid?
form.errors = {title: ["needs to be at least 10 characters"]}
form.title = "a bit longer :D"
form.title # "a bit longer :D"
form.insert
form.title = "A bit longer :D" # It capitalizes the title
```

Let's try updating a record

```crystal
task = TaskRows.first # Task(title: "Old title", description: "Old")
TaskForm.new(title: "Updated title").update(task)
task = TaskRows.first # Task(title: "Updated title", description: "Old")
```

## Advanced forms

You can inherit from other forms so your forms don't get too unwieldy

```crystal
class AdminTaskForm < TaskForm
  allow :created_at, :updated_at # These are chained, so you can also set :title and :description still

  def call
    previous_def # Run the parent classes validations, etc.
    let_people_know_an_admin_edited_this
  end

  private def let_people_know_an_admin_edited_this
    title = "#{title} - edited by an admin"
  end
end

# Now when you use this form you can set `created_at`, `updated_at` and when
# you insert or update the title will have `" - edit by an admin"` appended.

AdminTaskForm.new(title: "Something long", description: "test", created_at: 5.days.ago).insert

TaskRows.last # Task(title: "Something long - edited by an admin", created_at: #{date 4 days ago})
```

## Forms with associations

Let's make a form for Comments

```crystal
class CommentForm < Comment::BaseForm
  allow :body

  def call
    validate_length_of :body, min: 10
  end
end
```

Now let's allow setting them through the `TaskForm`

```crystal
class TaskForm < Task::BaseForm
  allow :title, :comments

  def call
    description = "some default description"
    process_assoc comments, with: CommentForm
  end
end

# Now we can do this
comments = [{body: "this is my comment"}]
form = TaskForm.new(title: "Something", comments: comments).insert
form.comments # [Comment(body: "this is my comments")]

# If a comment is invalid
comments = [{body: "short"}]
form = TaskForm.new(title: "Something", comments: comments)
form.valid? # false
form.errors # {comments: [CommentForm(errors)]}

# So you can do
form.errors[:comments].each do |comment_form|
  p comment_form.errors # {body: "is too short"}
end
```

## Callbacks

Callbacks only apply to the form they're declared in. This makes things
easier to follow, and easier to debug.

```crystal
class CommentForm < Task::BaseForm
  def call
    before_commit :touch_parent_task
  end

  private def touch_parent_task
    # assumes you have added a `field last_commented_at : Time` to the schema
    task.last_commented_at = Time.now
  end
end
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
