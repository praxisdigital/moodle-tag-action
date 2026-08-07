# moodle-tag-action

On a push into the repository default branch, create a git tag named after the Moodle plugin version from root `version.php`.

## Usage

Add a workflow in your Moodle plugin repository:

```yaml
name: Tag plugin version

on:
  push:

permissions:
  contents: write

jobs:
  tag:
    runs-on: ubuntu-latest
    steps:
      - uses: praxisdigital/moodle-tag-action@v1
```

The action checks out the repository itself. It only creates a tag when the event is a **push** to the repository **default branch**. Merges into that branch are push events, so they are covered. Pushes to other branches are skipped.

## How it works

1. Checks out the triggering commit
2. Runs only on `push` events
3. Skips unless the push targets the repository default branch
4. Reads `$plugin->version` from `./version.php` at the repository root
5. Creates an annotated tag named after that version on `github.sha` if the tag does not already exist
6. Pushes the tag using `github.token`

## Outputs

| Output | Description |
| --- | --- |
| `version` | Parsed Moodle plugin version number |
| `tag` | Full tag name |
| `created` | `true` if a new tag was pushed |

## Requirements

- Repository root must contain `version.php` with `$plugin->version = <integer>;`
- Workflow must grant `contents: write`
