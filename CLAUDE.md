# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A GitHub Actions Composite Action that installs [ghasec](https://github.com/koki-develop/ghasec) (a security linter for GitHub Actions) onto GitHub Actions runners. No build step — the project consists solely of a shell script (`install.sh`) and an Action definition (`action.yml`).

## Architecture

- `action.yml` — Composite Action definition. Inputs: `version` (default `latest`) and `token`. Passes inputs to `install.sh` via environment variables (`INPUT_VERSION`, `GITHUB_TOKEN`).
- `install.sh` — Handles the full installation pipeline: version resolution → platform detection → download → checksum verification → extraction → PATH registration.

## CI

- `.github/workflows/ci.yml` — Tests across 3 OS (`ubuntu-latest`, `macos-latest`, `windows-latest`) with 3 version patterns: `latest`, pinned version, and `v`-prefixed version.
- There are no locally runnable tests. Changes are verified on GitHub Actions.

## Release

Managed by release-please (`simple` type).

## Coding Conventions

- In `action.yml`, never embed `${{ inputs.xxx }}` directly in `run:` blocks. Always pass inputs via `env:` as environment variables (script injection prevention).
- In `install.sh`, use GitHub Actions default environment variables (`RUNNER_OS`, `RUNNER_ARCH`, `RUNNER_TEMP`, `GITHUB_PATH`).
- Pin actions by commit hash.
