# deploy-notes

Appends a repo's deploy instructions to a release notes file. The instructions live in the repo as a markdown template (default `.github/deploy.md`), so the action itself is generic.

## Template placeholders

| Placeholder | Value |
|---|---|
| `{{version}}` | `version` input |
| `{{previous_version}}` | `previous_version` input (optional; the action fails if the template uses it while it is empty) |
| `{{repo_name}}` | `repo_name` input, defaults to the current repository name |

## Usage

```yaml
- uses: qcode-software/ci-development/.github/actions/deploy-notes@<version>
  with:
    version: ${{ steps.version.outputs.version }}
    notes_file: ${{ runner.temp }}/notes.md
```

## Migrating a repo-local `tcl-module-deploy-markdown` copy

1. Copy the heredoc body from the repo's `actions/tcl-module-deploy-markdown/action.yml` (the text between `cat << "EOF" >> ...` and `EOF`, with the YAML indentation removed) into `.github/deploy.md`.
2. Replace `${{ inputs.version }}`, `${{ inputs.previous_version }}` and `${{ inputs.repo_name }}` in it with `{{version}}`, `{{previous_version}}` and `{{repo_name}}`.
3. If the body has a `Backout` section using `{{previous_version}}`, make sure the caller passes `previous_version`; otherwise drop the section. Bodies that never used it (for example the `tlc-lib` style) need no change.
4. Replace the local action call with the shared one and delete the local action directory.
