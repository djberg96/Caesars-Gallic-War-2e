# Caesar's Gallic War

Rails 8.1 / Ruby 4 browser adaptation of the second edition boardgame.

## Run

On FreeBSD with rbenv:

```sh
cd game
MAKE=gmake bundle install --jobs 1
bundle exec rails server
```

Then open `http://localhost:3000`.

The current version is a hotseat playable board prototype. It uses the rulebook
repository's own `Misc/map_points.json`, `images/Map/CGW_Map.jpg`, and counter
SVGs as source assets.

## AI config

AI credentials are local-only and ignored by git. To prepare for AI opponent
work:

```sh
cp config/ai.yml.example config/ai.yml
```

Then edit `config/ai.yml` with the provider, model, base URL, and API key. The
UI detects whether the file is configured, but API calls are not wired yet.

Implemented now:

- Rails 8.1 app pinned to Ruby 4.0.4
- production map image displayed as the board
- counter data scanned from the SVG assets
- second edition initial setup, including random variable tribes
- current-player hand visibility, basic card actions, movement helpers, political rolls, dice battles,
  strength reduction, save/load, and JSON export
- browser quick-save plus named JSON save/load files
- hotseat, first-pass solitaire Roman mode, and AI-opponent configuration placeholder

Still to refine:

- exact final card roster and AP distribution
- full enforcement for reserves, retreats, regroup, pinning, sieges, and wintering
- full solitaire bot behavior
- persistent saved games

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
