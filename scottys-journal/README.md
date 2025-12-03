# Scotty's Engineering Journal

This directory contains automated logging for git operations, build performance, and system state changes.

## Structure

- `logs/` - Narrative log entries in Starfleet engineering log format
- `metrics/` - CSV files tracking performance and operational data

## Generated Files

- `logs/YYYY-MM-DD-automated.log` - Daily automated entries
- `metrics/build-performance.csv` - Build timing and success rates
- `metrics/git-operations.csv` - Git operation tracking
- `metrics/error-tracking.csv` - Error resolution tracking

## Data Sources

Generated automatically by:
- Git hooks (pre-commit, post-commit, pre-push)
- Build scripts
- System rebuild operations

Managed by `scotty-logging-lib.sh` in the Nix store.