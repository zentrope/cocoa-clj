# cocoa-clj

Challenge: build a Mac app that interacts with Clojure in some useful way.

## Usage

To open the Xcode project (so you can run the client) and run the
server:

``` shellsession
make open server
```

Full options:

``` shellsession
help                      Show makefile based help
open                      Open the application in Xcode
outdated                  Check for outdated server dependencies
server                    Run the backend server
```

## Run server from github

If I gave you a binary of the Mac App, you could use the following in
a terminal window to run the server side:

    clojure -Sdeps '{:deps,{zentrope/cocoa-clj { \
      :git/url "https://github.com/zentrope/cocoa-clj" \
      :sha "2b9ec07e3763b3386e129f6b2c2e93ca1cad0f96" \
      :deps/root "server"}}}' \
      -m zentrope.cljapp.main

without cloning the source code. Eventually, the app itself should
have an option to do this for you if you want to run it against a
non-project JVM.

Ideally, the client would use a socket-repl, but I'm waiting for some
SDKs from Mojave before I work on that.

## Application

- Xcode-beta 4
- Swift 4.2
- High Sierra

## Server

- Requires a custom web-service in your clojure app.
- [Clojure CLI](https://clojure.org/guides/getting_started)
- Make

## License

Copyright (c) 2018-present Keith Irwin

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see
[http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
