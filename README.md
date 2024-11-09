# Avram

[![API Documentation Website](https://img.shields.io/website?down_color=red&down_message=Offline&label=API%20Documentation&up_message=Online&url=https%3A%2F%2Fluckyframework.github.io%2Favram%2F)](https://luckyframework.github.io/avram)

Database ORM built for the [Lucky Framework](https://luckyframework.org/) written in Crystal. Supporting PostgreSQL 12+ and based off principals of [Elixir Ecto](https://hexdocs.pm/ecto/Ecto.html) and [Rails ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html).

### Why Avram?

The name comes from [Henriette Avram](https://en.wikipedia.org/wiki/Henriette_Avram).

> Henriette Davidson Avram (October 7, 1919 – April 22, 2006) was a computer programmer and systems analyst who developed the MARC format (Machine Readable Cataloging), the international data standard for bibliographic and holdings information in libraries.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  avram:
    github: luckyframework/avram
```

## Usage

```crystal
require "avram"

# Define your database
class AppDatabase < Avram::Database
end

AppDatabase.configure do |settings|
  settings.credentials = Avram::Credentials.new(
    database: "my_app_development",
    username: "postgres",
    hostname: "localhost",
    password: "password",
    port: 5432,
  )
end

# Configure Avram to use your database
Avram.configure do |settings|
  settings.database_to_migrate = AppDatabase

  # When `true`, allow lazy loading (N+1).
  # If `false` raise an error if you forget to preload associations
  settings.lazy_load_enabled = true
  settings.query_cache_enabled = false
end

# Create your read-only model
class Person < Avram::Model
  def self.database : Avram::Database.class
    AppDatabase
  end

  table :people do
    column name : String
    column age : Int32
    column programmer : Bool = true
  end
end

# Insert a new record
Person::SaveOperation.create!(name: "Henriette Davidson Avram", age: 86)
# Query for a record
person = Person::BaseQuery.new.name.ilike("%avram")
person.programmer? #=> true
```

For more details, read the [guides](https://luckyframework.org/guides/database/intro-to-avram-and-orms).

## Contributing

1. Fork it ( https://github.com/luckyframework/avram/fork )
1. Create your feature branch (git checkout -b my-new-feature)
1. Make your changes
1. Run specs `crystal spec`
1. Check formatting `crystal tool format spec/ src/`
1. Check ameba `./bin/ameba`
1. Commit your changes (git commit -am 'Add some feature')
1. Push to the branch (git push origin my-new-feature)
1. Create a new Pull Request

> Docker is provided for quick setup and testing. You can run `./script/setup` and `./script/test` for ease.

## Contributors

[paulcsmith](https://github.com/paulcsmith) Paul Smith - Original Creator of Lucky

<a href="https://github.com/luckyframework/avram/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=luckyframework/avram" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
