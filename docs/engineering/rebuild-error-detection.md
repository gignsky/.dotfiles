# Rebuild Error Detection Enhancement

**Stardate:** 2026-03-10  
**Engineer:** Chief Engineer Montgomery Scott  
**Status:** ✅ Complete

## Problem Statement

Previously, when `just rebuild` or `just home` commands failed, the error messages were hidden because the scripts suppressed output in non-verbose mode. Users would see only "❌ Build failed" without any indication of what went wrong, making debugging extremely difficult.

## Solution Implemented

Enhanced both `nixos-rebuild.sh` and `home-switch.sh` with intelligent error extraction and display:

### Key Features

1. **Smart Error Pattern Matching**
   - Searches for common Nix error patterns: `error:`, `attribute.*missing`, `undefined variable`, `syntax error`, `builder for.*failed`
   - Also catches home-manager specific errors like `collision between`
   - Extracts and displays only the relevant error lines, not the entire 1000+ line build log

2. **Progressive Error Display**
   - If error patterns are found: Shows extracted error messages prominently
   - If no patterns match: Falls back to showing last 10 lines of output
   - Always preserves full build log in temp file for detailed debugging

3. **User-Friendly Output Format**
   ```
   ❌ nixos-rebuild failed with exit code: 1
   
   === 🔍 EXTRACTING ERROR MESSAGES FROM BUILD LOG ===
   
   🚨 KEY ERROR MESSAGES:
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     error: attribute 'guid' missing
     error: builder for '/nix/store/...' failed with exit code 1
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   💡 To see full build output, run with --verbose flag or check: /tmp/tmp.xyz123
   ```

4. **Output Capture Strategy**
   - Normal mode: Captures all output to temp file, only displays on error
   - Verbose mode: Shows all output via `tee` while still capturing for analysis
   - Exit codes properly tracked using `${PIPESTATUS[0]}` to avoid false positives

5. **Temp File Management**
   - Creates separate temp files for full output and extracted errors
   - Cleans up temp files on successful builds
   - Preserves full output file on failure for detailed debugging
   - Provides path to full log for users who need more context

## Files Modified

### `/home/gig/.dotfiles/scripts/nixos-rebuild.sh`
- Added `error_log_file` temp file for extracted errors
- Implemented multi-pattern grep search for common Nix errors
- Enhanced failure output with prominent error display
- Improved user guidance with verbose flag instructions

### `/home/gig/.dotfiles/scripts/home-switch.sh`
- Parallel implementation of same error extraction logic
- Added home-manager specific error patterns
- Consistent output format with nixos-rebuild script
- Proper temp file cleanup on success/failure

### `/home/gig/.dotfiles/scripts/test-error-extraction.sh` (NEW)
- Test harness to verify error extraction logic works correctly
- Creates sample Nix build failure output
- Validates grep patterns match expected errors
- Provides statistics on extraction efficiency

## Testing

```bash
# Test the error extraction logic
./scripts/test-error-extraction.sh

# Test rebuild scripts with simulated failure
# (Would require actual Nix configuration errors to fully test)
just rebuild      # Normal mode - errors should be extracted and displayed
just rebuild -v   # Verbose mode - full output shown including errors
```

## Error Patterns Detected

| Pattern | Example | Purpose |
|---------|---------|---------|
| `error:` | `error: attribute 'guid' missing` | Catches all Nix evaluation errors |
| `attribute.*missing` | `error: attribute 'foo' missing` | Specifically highlights missing attribute errors |
| `undefined variable` | `error: undefined variable 'bar'` | Catches unbound variable references |
| `syntax error` | `syntax error, unexpected '}'` | Highlights Nix syntax issues |
| `builder for.*failed` | `builder for '/nix/store/...' failed` | Shows build-time failures |
| `collision between` | `collision between 'file1' and 'file2'` | Home-manager file conflicts |

## Benefits

1. **Faster Debugging**: Engineers immediately see what failed without scrolling through logs
2. **Reduced Context Switching**: No need to re-run with verbose flags in most cases
3. **Better User Experience**: Clear, actionable error messages instead of cryptic failures
4. **Preserved Detail**: Full logs still available when needed for complex issues
5. **Consistent Interface**: Same error display format for both system and home rebuilds

## Future Enhancements

Potential improvements for future implementation:
- Add more error patterns as we encounter new failure modes
- Color-code error messages based on severity
- Provide automatic suggestions for common errors (e.g., "Did you mean 'gid'?")
- Integration with Scotty's logging system for automatic error analysis
- Pattern matching for specific file/line number extraction

## Usage Examples

### Normal rebuild (shows errors if any):
```bash
just rebuild
```

### Verbose rebuild (shows everything):
```bash
just rebuild -v
# or with the script directly:
nix run .#nixos-rebuild -- --verbose
```

### Check full logs after failure:
```bash
# Path is shown in error output, typically:
cat /tmp/tmp.abc123  # Replace with actual temp file path
```

## Engineering Notes

The key insight was recognizing that Nix errors are often buried in the middle of verbose build output, not at the end. Traditional approaches of showing "last N lines" often missed the actual error. By using targeted grep patterns, we extract exactly the information needed for debugging.

The implementation uses standard bash tools (grep, mktemp, sed) to ensure portability across all NixOS systems without additional dependencies.

---

**Chief Engineer's Sign-off:**  
Montgomery Scott  
Stardate 2026-03-10T16:45:00Z

*"The engines may fail, but they'll tell ye why they failed!"*
