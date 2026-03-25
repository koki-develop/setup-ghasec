# setup-ghasec

A GitHub Action to install [ghasec](https://github.com/koki-develop/ghasec), a security linter for GitHub Actions workflows.

## Usage

<!-- x-release-please-start-version -->
```yaml
- uses: koki-develop/setup-ghasec@v1.0.0
```
<!-- x-release-please-end -->

### Inputs

| Name | Description | Default |
| --- | --- | --- |
| `version` | Version to install (e.g. `X.Y.Z`, `vX.Y.Z`, or `latest`) | `latest` |
| `token` | GitHub token for API requests (to avoid rate limiting) | `${{ github.token }}` |

### Example

<!-- x-release-please-start-version -->
```yaml
name: ghasec

on:
  pull_request:
  push:
    branches: [main]

jobs:
  ghasec:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: koki-develop/setup-ghasec@v1.0.0
      - run: ghasec --format=github-actions
```
<!-- x-release-please-end -->

## License

[MIT](./LICENSE)
