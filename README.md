# InContext

[![build](https://github.com/inseven/incontext/actions/workflows/build.yaml/badge.svg)](https://github.com/inseven/incontext/actions/workflows/build.yaml)

Multimedia-focused static site builder for macOS

## Installation

InContext can be installed using [Homebrew](https://brew.sh):

```bash
brew install inseven/incontext/incontext
```

## Documentation

See [https://incontext.jbmorley.co.uk/docs](https://incontext.jbmorley.co.uk/docs).

## Frontmatter

Frontmatter is supported in Markdown files and image and video descriptions. InContext will pass through all unknown markdown fields, but puts type constraints on fields that have specific meaning:

- `title` String?
- `subtitle` String?
- `date` Date?
- `queries` [[String: Any]]?
- `tags` [String]?

## Issues

### Background

- Test that the relative paths are correct for the destination directory; this likely needs to be per-importer, but it would be much easier if we had a way to generate these as part of the site so importers don't have to think too hard
- Store the origin mime type in the database and expose through `DocumentContext`

## License

InContext is licensed under the MIT License (see [LICENSE](https://github.com/inseven/incontext/blob/main/LICENSE)). It depends on the following separately licensed third-party libraries and components:

- [Backtrace](https://github.com/swift-server/swift-backtrace), Apache License, Version 2.0
- [Diligence](https://github.com/inseven/diligence), MIT License
- [FSEventsWrapper](https://github.com/Frizlab/FSEventsWrapper), MIT License
- [Hoedown](https://github.com/hoedown/hoedown), ISC License
- [Hummingbird](https://github.com/hummingbird-project/hummingbird), Apache License, Version 2.0
- [HummingbirdCore](https://github.com/hummingbird-project/hummingbird-core), Apache License, Version 2.0
- [Interact](https://github.com/inseven/interact), MIT License
- [Licensable](https://github.com/inseven/licensable), MIT License
- [LRUCache](https://github.com/nicklockwood/LRUCache), MIT License
- [LuaSwift](https://github.com/tomsci/LuaSwift), MIT License
- [NIO Transport Services](https://github.com/apple/swift-nio-transport-services), Apache License, Version 2.0
- [NIOExtras](https://github.com/apple/swift-nio-extras), Apache License, Version 2.0
- [SQLite.swift](https://github.com/stephencelis/SQLite.swift), MIT License
- [Swift Algorithms](https://github.com/apple/swift-algorithms), Apache License, Version 2.0
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser), Apache License, Version 2.0
- [Swift Atomics](https://github.com/apple/swift-atomics), Apache License, Version 2.0
- [Swift Collections](https://github.com/apple/swift-collections), Apache License, Version 2.0
- [Swift Crypto](https://github.com/apple/swift-crypto), Apache License, Version 2.0
- [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing), Apache License, Version 2.0
- [Swift HTTP Structured Headers](https://github.com/apple/swift-http-structured-headers), Apache License, Version 2.0
- [Swift HTTP Types](https://github.com/apple/swift-http-types), Apache License, Version 2.0
- [Swift Numerics](https://github.com/apple/swift-numerics), Apache License, Version 2.0
- [Swift Service Context](https://github.com/apple/swift-service-context), Apache License, Version 2.0
- [Swift Service Lifecycle](https://github.com/swift-server/swift-service-lifecycle), Apache License, Version 2.0
- [Swift System](https://github.com/apple/swift-system), Apache License, Version 2.0
- [SwiftLog](https://github.com/apple/swift-log), Apache License, Version 2.0
- [SwiftMetrics](https://github.com/apple/swift-metrics), Apache License, Version 2.0
- [SwiftNIO](https://github.com/apple/swift-nio), Apache License, Version 2.0
- [SwiftNIO HTTP/2](https://github.com/apple/swift-nio-http2), Apache License, Version 2.0
- [SwiftNIO SSL](https://github.com/apple/swift-nio-ssl), Apache License, Version 2.0
- [SwiftSoup](https://github.com/scinfu/SwiftSoup), MIT License
- [Tilt](https://github.com/tomsci/tomscis-lua-templater), MIT License
- [Titlecaser](https://github.com/jwells89/Titlecaser), MIT License
- [Yams](https://github.com/jpsim/Yams), MIT License
