# Tonie Shuffle

A command-line utility to shuffle [Creative Tonie](https://tonies.de/kreativ-tonies) playlists.

I made this simple utility because I wanted to have some of our Tonies play their music in random order.

It has two modes:
1. Shuffle a specific Tonie by specifying its exact household and Tonie IDs (which the utility can list if necessary).
2. Shuffle all Tonies whose name match a specific pattern (currently, ending with `[s]`).

This project includes a minimal, Dart-native implementation of the Tonies API inspired on [toniebox-api](https://github.com/maximilianvoss/toniebox-api) by Maximilian Voß.

## Usage

Start by logging in with your Tonie credentials. Once logged in, a token will be stored under `$HOME/.tonie-shuffle/token` and used for future operations.
> _Note: The tokens will be stored in plaintext in the `token` file._

``` shell
$ tonie-shuffle login your@email.tld passw0rd
```

There are multiple commands available, but you probably want to automatically shuffle every Tonie whose name ends with `[s]`:

``` shell
$ tonie-shuffle autoshuffle
```

Otherwise, simply run the utility without arguments to get a comprehensive usage description.

## Setup

You'll need at least Dart 2.7. Get it at https://dart.dev.

Simply clone the repository, change into the project directory and update the dependencies:

``` shell
$ pub get
```

Though the utility can be run as interpreted dart code, it works best as a precompiled executable:

``` shell
$ dart2native bin/main.dart -o tonie-shuffle
```

Also consider installing the binary in your path, or moving it to a standard bin folder:

``` shell
$ sudo mv tonie-shuffle /usr/local/bin
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/cachapa/tonie_shuffle/issues).

## License

Apache License Version 2.0
