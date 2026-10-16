# Agent Instructions

## AI-Generated Files

Whenever a new file is fully authored using AI:

- Add it to the AI disclosure page, `docs/content/ai/index.md`, following the existing patterns: list it under the section matching its location (e.g., 'Core' for `Sources/InContextCore`, 'Tests' for `Tests`), adding a new section if none fits, using the `link` function with the file's repository-relative path, and an optional short `-- description` of its purpose.

- Add a comment directly below the file's copyright (licence) header stating that it was initially generated using AI, naming the model and its version. For example:

  ```swift
  // SOFTWARE.

  // Initially generated using AI (Claude Opus 5.5).

  import Foundation
  ```
