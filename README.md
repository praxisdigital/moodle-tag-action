# moodle-tag-action

Create a git tag from the Moodle plugin version number when a pull request is merged.

## Usage

```yaml
name: Tag Moodle release

on:
  pull_request_target:
    types:
      - closed

jobs:
  tag:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.merge_commit_sha }}

      - uses: praxisdigital/moodle-tag-action@<release-tag>
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

By default the action reads `version.php`, extracts `$plugin->version`, and creates that value as the git tag. Use `tag_prefix` if you want to prepend a prefix such as `v`. Pin the action to a published release tag such as `v1`.
