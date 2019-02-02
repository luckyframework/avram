# Avram

This project is still new. Guides will be posted when things are more complete.

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
```

## Contributing

1. Fork it ( https://github.com/luckyframework/avram/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Make your changes
4. Run `./bin/test` to run the specs, build shards, and check formatting
5. Commit your changes (git commit -am 'Add some feature')
6. Push to the branch (git push origin my-new-feature)
7. Create a new Pull Request

## Testing

To run the tests:

* Install Postgres: ([macOS](https://postgresapp.com)/[Others](https://wiki.postgresql.org/wiki/Detailed_installation_guides))
* Migrate the database using `crystal tasks.cr db.reset`
* Run the tests with `crystal spec`

## Contributors

- [paulcsmith](https://github.com/paulcsmith) Paul Smith - creator, maintainer
- [mikeeus](https://github.com/mikeeus) Mikias Abera - contributor
