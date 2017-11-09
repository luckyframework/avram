# LuckyRecord

This project is still new. Guides will be posted when things are more complete.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  lucky_record:
    github: luckyframework/record
```

## Usage

```crystal
require "lucky_record"
```

## Contributing

1. Fork it ( https://github.com/luckyframework/lucky_record/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Testing

To run the tests:

* Install Postgres: ([macOS](https://postgresapp.com)/[Others](https://wiki.postgresql.org/wiki/Detailed_installation_guides))
* Migrate the database using `crystal tasks.cr db.reset`
* Run the tests with `crystal spec`

## Contributors

- [paulcsmith](https://github.com/paulcsmith) Paul Smith - creator, maintainer
