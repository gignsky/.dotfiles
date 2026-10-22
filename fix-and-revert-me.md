Need to resolve, then revert the commit that added this file.

This issue appears when using 'vi' or 'gigvim' (which needs to be updated).

```
giglab.dev on  roll/1-1022-publish via ❄️  impure (nix-shell-env)
 > vi site/package.json
Warning: nu::shell::deprecated

  ⚠ Positional completer input deprecated.
    ╭─[/nix/store/1i10d66yy5vwf8zmjshb768fjp73wpdd-carapace-nushell-config.nu:7:26]
  6 │
  7 │ ╭─▶ let carapace_completer = {|spans|
  8 │ │     load-env {
  9 │ │       CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq  | str join "\n")
 10 │ │       CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq  | str join "\n")
 11 │ │     }
 12 │ │
 13 │ │     # if the current command is an alias, get it's expansion
 14 │ │     let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)
 15 │ │
 16 │ │     # overwrite
 17 │ │     let spans = (if $expanded_alias != null  {
 18 │ │       # put the first word of the expanded alias first in the span
 19 │ │       $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
 20 │ │     } else {
 21 │ │       $spans | skip 1 | prepend ($spans.0)
 22 │ │     })
 23 │ │
 24 │ │     carapace $spans.0 nushell ...$spans
 25 │ │     | from json
 26 │ ├─▶ }
    · ╰──── declares the legacy positional input `spans`
 27 │
    ╰────
  help: A command or external completer is handed one record, whose fields bind to the
        parameters it names: token, place, buffer. `spans` still receives its old
        positional value for compatibility, but this bridge will be removed in a future
        release. To migrate, use `[place]` and read `$place.command` for the token list
        of the command being completed, or `[buffer]` for the whole line.
```
