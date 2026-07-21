# Caesar's Gallic War

Rails 8.1 / Ruby 4 browser adaptation of the second edition boardgame.

## Development setup

The application uses Ruby 4.0.4, Rails 8.1, Bundler 4.0.15, and SQLite. Ruby's
version is recorded in `.ruby-version`. JavaScript is delivered through Rails
import maps, so Node and Yarn are not required.

After completing the operating-system instructions below, use the common setup
steps to install the gems, create the local database, and start Rails.

### macOS

Install the Xcode command-line tools and [Homebrew](https://brew.sh/), then use
Homebrew to install rbenv, ruby-build, and Ruby's build dependencies:

```sh
xcode-select --install
brew install rbenv ruby-build openssl@3 readline libyaml gmp autoconf
rbenv init
```

Restart the terminal after `rbenv init`, then continue with the common setup
steps below. These commands work on both Apple Silicon and Intel Macs.

### Linux

Install Ruby's compiler dependencies before installing rbenv.

On Debian, Ubuntu, or Mint:

```sh
sudo apt update
sudo apt install -y git build-essential autoconf libssl-dev libyaml-dev \
  zlib1g-dev libffi-dev libgmp-dev rustc libsqlite3-dev sqlite3
```

On Fedora 40 or newer:

```sh
sudo dnf install -y git autoconf gcc rust patch make bzip2 openssl-devel \
  libyaml-devel libffi-devel readline-devel gdbm-devel ncurses-devel \
  perl-FindBin zlib-ng-compat-devel sqlite-devel
```

Then install rbenv and ruby-build:

```sh
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
~/.rbenv/bin/rbenv init
```

Restart the terminal, then run:

```sh
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
```

Continue with the common setup steps below.

### Windows

#### WSL 2 (recommended)

The closest match to the Linux development and production environment is
[WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install). From an
Administrator PowerShell window, install Ubuntu:

```powershell
wsl --install -d Ubuntu
```

Restart Windows if requested, open Ubuntu, and follow the Debian/Ubuntu Linux
instructions above. For best filesystem performance, clone the repository
inside the WSL home directory (for example, `~/src`) rather than under
`/mnt/c`.

#### Native Windows

Install [Git for Windows](https://git-scm.com/download/win) and the
[Ruby+Devkit 4.0.x installer](https://rubyinstaller.org/downloads/). The
repository is developed with Ruby 4.0.4; a newer Ruby 4.0 patch release should
also work. Select the MSYS2 development kit during installation and run
`ridk install` if the installer does not run it automatically.

Open a new PowerShell window and run:

```powershell
ridk enable
git clone https://github.com/djberg96/Caesars-Gallic-War-2e.git
Set-Location .\Caesars-Gallic-War-2e\game
gem install bundler -v 4.0.15
bundle install
bundle exec rails db:prepare
bundle exec rails server
```

Then open `http://localhost:3000`. If native gem compilation fails, confirm
that the Ruby+Devkit installer was used and run `ridk install` again, or use
the WSL setup instead.

### FreeBSD

With rbenv and ruby-build installed, install the required build tools and
libraries:

```sh
# Run as root.
pkg install git autoconf bison patch gcc rust gdbm gmake libffi \
  libyaml ncurses openssl readline sqlite3
```

Continue with the common setup, but use GNU make while Bundler builds gems:

```sh
cd game
rbenv install -s "$(cat .ruby-version)"
gem install bundler -v 4.0.15
MAKE=gmake bundle install --jobs 1
bin/rails db:prepare
bin/rails server
```

### Common setup (macOS and Linux)

From the cloned repository:

```sh
cd game
rbenv install -s "$(cat .ruby-version)"
gem install bundler -v 4.0.15
bundle install
bin/rails db:prepare
bin/rails server
```

Open `http://localhost:3000`.

## Desktop installer

The Windows desktop package includes Ruby, Rails, and all game assets. Players
do not need to install Ruby or use a terminal: the installer creates a normal
Start-menu shortcut that starts a private server on `127.0.0.1` and opens the
game in the default browser. Game data and logs are kept in the current user's
application-data directory rather than the installation directory.

To produce an installer, run the **Windows desktop installer** workflow from
the repository's Actions page and supply a version number. Pushing a tag such
as `v0.1.0` also builds it. The downloadable workflow artifact contains
`Caesars-Gallic-War-0.1.0-Windows-x64-Setup.exe`.

The launcher in `bin/desktop` also supports macOS and Linux and provides the
base for native packages on those platforms. From an existing development
checkout it can be tried with:

```sh
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile
bin/desktop
```

Windows installers are currently unsigned, so Windows may display a
SmartScreen warning. A public release should sign the generated installer with
an Authenticode certificate; macOS packages will likewise need Apple signing
and notarization.

The SQLite development and test databases are stored under `game/storage/`
and are ignored by git. To run the test suite:

```sh
bin/rails test
```

The current version is a playable browser adaptation. It uses
`config/data/map_points.json`, `../images/Map/CGW_Map_atlas.png`, and the
counter images under `../images/Blocks/` as source assets.

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
- hotseat, first-pass solitaire Roman mode, and AI-opponent configuration placeholder

Still to refine:

- exact final card roster and AP distribution
- full enforcement for reserves, retreats, regroup, pinning, sieges, and wintering
- full solitaire bot behavior
- persistent saved games
