# cocoa-clj

Challenge: build a Mac app that interacts with Clojure in some useful way.

## Usage

To open the Xcode project and run the server:

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
      :sha "50e53b9bf56a48568a214be7866ec7e7d01455c3" \
      :deps/root "server"}}}' \
      -m zentrope.cljapp.main

to run the server without cloning out the source code. Eventually, the
app itself should have an option to do this for you if you want to run
it against a non-project JVM.

## Application

- Xcode-beta 3
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
