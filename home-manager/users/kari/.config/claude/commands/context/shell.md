
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

# Shell script context (tupakkatapa house style)

Conventions for bash scripts across any project. The canonical `say()` pattern comes from `~/Workspace/local/majbacka-labs/nixie/packages/refind-generate/refind-generate.sh:29`. This file is the **target idiom** — `mozid.sh` and `gh-envsync.sh` are pre-idiom scripts and will be aligned as they're touched; new scripts follow this file from the start.

Linked from `/tt:context:nix`, `/tt:context:rust`, and `/tt:context:javascript` — any project's shell scripts follow this file.

## Shebang & strict mode

```bash
#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' SIGINT     # silent exit on Ctrl-C (omit if you need a stack trace)
```

- `#!/usr/bin/env bash` — portable; never `/bin/bash`.
- `set -euo pipefail` — fail on error, undefined vars, pipe failures.
- Use `set -o pipefail` alone (no `-e`) only when you need to continue past per-command failures and have explicit handling — nixie's `refind-generate.sh` is an example.

## Channel discipline

- **stdout** = pipeable results (data the caller might pipe into another tool).
- **stderr** = diagnostics (progress, warnings, errors).
- **exit code** = status.

Never mix progress chatter into stdout — it breaks piping. If a script has no pipeable output, all output goes to stderr.

## The `say()` helper

Single diagnostic helper. All chatter to stderr; verbose gating built in.

**Verbatim from nixie/packages/refind-generate/refind-generate.sh:29**, kept faithful so the documented idiom matches the canonical source:

```bash
verbose=false

# Output function with optional verbose-only mode and timestamps
# Usage:
#   say "message"          - always shown (with timestamp if verbose enabled)
#   say verbose "message"  - only shown when verbose flag is set
say() {
  local message
  local verbose_only=false

  # Check if first argument is "verbose"
  if [[ $1 == "verbose" ]]; then
    verbose_only=true
    shift
  fi

  message="$*"

  # Skip if verbose-only and not in verbose mode
  if [[ $verbose_only == true ]] && [[ $verbose == false ]]; then
    return
  fi

  # Add timestamp if verbose mode is enabled
  if [[ $verbose == true ]]; then
    echo "[$(date '+%H:%M:%S')] $message" >&2
  else
    echo "$message" >&2
  fi
}

die() { say "$@"; exit 1; }
```

Why one helper instead of `info`/`log`/`warn`/`err`/`die`:
- One source of truth; verbose gating in one place.
- Four-helper variants drift apart over time (different formats, different streams).
- `say verbose "..."` reads as English; intent obvious at the call site.

Add a colour wrapper only when the script is interactive *and* coloured output adds information (severity, structure):

```bash
if [[ -t 2 ]]; then
  red=$'\033[31m'; yellow=$'\033[33m'; reset=$'\033[0m'
else
  red=''; yellow=''; reset=''
fi
```

Then call sites can write `say "${red}error:${reset} oh no"` when severity matters. Resist colour creep — most scripts don't need it.

## Argument parsing

Explicit `case` statements. Error on unknown flags:

```bash
positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose) verbose=true; shift ;;
    --foo)        foo="$2"; shift 2 ;;
    --foo=*)      foo="${1#*=}"; shift ;;
    -h|--help)    display_usage; exit 0 ;;
    --)           shift; break ;;
    -*)           die "unknown flag: $1" ;;
    *)            positional+=("$1"); shift ;;
  esac
done
```

- Support both `--foo value` and `--foo=value` forms.
- `--` terminates flag parsing; collect remainder as positional args.
- `getopts` is acceptable for short flags only; the `case` pattern handles long flags cleanly.

## Quoting & safety

- Quote every expansion: `"$var"`, `"${array[@]}"`, `"$(command)"`. Unquoted = wordsplit + glob bugs.
- Use arrays for argument lists, never strings:
  ```bash
  declare -a nix_flags=(
    --accept-flake-config
    --extra-experimental-features 'nix-command flakes'
    --impure
    --no-warn-dirty
    --refresh
  )
  nix build "${nix_flags[@]}" .#thing
  ```
  (Pattern lifted from nixie's `refind-generate.sh:17`.)
- Check for required tools at startup, not at first use:
  ```bash
  for tool in nix git jq; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool not found in PATH"
  done
  ```
- Use `mktemp` for temporary files; `trap` cleanup:
  ```bash
  tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT
  ```
- Avoid `eval`. If you think you need it, you almost certainly don't.

## Function structure

- Functions extract reusable logic, never just to shorten `main`.
- Each function does one thing; name describes the result, not the steps.
- Return values via stdout + exit code, never via globals (with the exception of script-scope config like `$verbose`).
- Local variables declared with `local`: `local foo="$1"`.

## Usage & help

Every non-trivial script has `display_usage`:

```bash
display_usage() {
  cat <<USAGE
Usage: <name> [OPTIONS...] [ARGS]

Description:
  <one paragraph>

Options:
  -v, --verbose     Enable verbose output.
  --foo VALUE       <description>
  -h, --help        Show this help and exit.

Examples:
  <name> --foo bar
USAGE
}
```

Show on `-h`/`--help` and on argument errors. Exit 0 on `--help`, exit 1 on bad args.

## Packaging shell scripts via Nix

`stdenv.mkDerivation` with `makeWrapper` and `substituteAll` for path injection:

```nix
stdenv.mkDerivation {
  pname = "my-script";
  version = "0.1.0";
  src = ./.;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    install -Dm755 my-script.sh $out/bin/my-script
    wrapProgram $out/bin/my-script \
      --prefix PATH : ${lib.makeBinPath [ jq nix git ]}
  '';
}
```

`wrapProgram` guarantees the script's runtime dependencies are reachable without polluting the user's `PATH`. See `mozid/lib.nix` and `gh-dotenv-sync/flake.nix` for two real examples.

## Lint & format

Shell-script linting/formatting is opt-in per project — not part of the default Nix-context treefmt stack. When a project ships non-trivial shell scripts, add to the `treefmt.config.programs` block:

```nix
programs = {
  # ... base stack from /tt:context:nix ...
  shellcheck.enable = true;
  shfmt.enable = true;
};
```

- **`shellcheck`** clean — non-negotiable once enabled.
- **`shfmt`** for formatting (2-space indent, default style).
- **No `# shellcheck disable=SCxxxx` without a justifying comment** on the line above naming the SC code and the reason (e.g. `# intentional word splitting: each token is a separate flag`). Matches the global rule in `~/.claude/CLAUDE.md`.

## Gotchas
- `[[ ... ]]` is bash; `[ ... ]` is POSIX. Inside `#!/usr/bin/env bash`, prefer `[[ ... ]]` — better quoting, regex support, no word-splitting traps.
- `$(...)` over backticks. Always.
- `${var:-default}` for safe defaults; `${var:?error message}` to assert presence.
- `read -r` to disable backslash interpretation (you almost always want this).
- `IFS` resets per function; explicit `local IFS=$'\n'` when iterating lines.
- `set -e` interacts poorly with functions called in `if` / `&&` / `||` contexts — read the bash man page on `errexit` before relying on it in complex control flow.
