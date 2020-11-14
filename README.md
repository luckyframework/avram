# Avram

[![API Documentation Website](https://img.shields.io/website?down_color=red&down_message=Offline&label=API%20Documentation&up_message=Online&url=https%3A%2F%2Fluckyframework.github.io%2Favram%2F)](https://luckyframework.github.io/avram)

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
```

## Contributing

1. Fork it ( https://github.com/luckyframework/avram/fork )
1. Create your feature branch (git checkout -b my-new-feature)
1. Install docker and docker-compose: https://docs.docker.com/compose/install/
1. Run `script/setup`
1. Make your changes
1. Run `script/test` to run the specs, build shards, and check formatting
1. Commit your changes (git commit -am 'Add some feature')
1. Push to the branch (git push origin my-new-feature)
1. Create a new Pull Request

## Testing

To run the tests:

1. Install docker and docker-compose: https://docs.docker.com/compose/install/
1. Run `script/setup` to set up the docker environment
1. Run `script/test` to run the specs, build shards, and check formatting

You can run individual tests like this: `docker-compose run --rm app crystal spec path/to/spec.cr`

> Remember to run `docker-compose down` when you're done. This will stop the
> Crystal container.

## Contributors

- [paulcsmith](https://github.com/paulcsmith) Paul Smith - creator, maintainer
- [mikeeus](https://github.com/mikeeus) Mikias Abera - contributor
