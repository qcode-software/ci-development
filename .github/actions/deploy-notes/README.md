# deploy-notes

Appends a repo's deploy instructions to a release notes file. The instructions live in the repo as a markdown template (default `.github/deploy.md`), so the action itself is generic.

## Template placeholders

| Placeholder | Value |
|---|---|
| `{{version}}` | `version` input |
| `{{repo_name}}` | `repo_name` input, defaults to the current repository name |

`{{previous_version}}` is not supported. It was never populated by `version-increment`, so every repo that used it rendered a blank. Any occurrence is removed from the template rather than left to appear literally.

## Usage

```yaml
- uses: qcode-software/ci-development/.github/actions/deploy-notes@<version>
  with:
    version: ${{ steps.version.outputs.version }}
    notes_file: ${{ runner.temp }}/notes.md
```

## Migrating a repo-local `tcl-module-deploy-markdown` copy

1. Copy the heredoc body from the repo's `actions/tcl-module-deploy-markdown/action.yml` (the text between `cat << "EOF" >> ...` and `EOF`, with the YAML indentation removed) into `.github/deploy.md`.
2. Replace `${{ inputs.version }}` and `${{ inputs.repo_name }}` in it with `{{version}}` and `{{repo_name}}`.
3. Delete any `Backout` section built from `${{ inputs.previous_version }}`. It has always rendered without a version, so it was never usable. Bodies that never used it (for example the `tlc-lib` style) need no change.
4. Replace the local action call with the shared one and delete the local action directory.
