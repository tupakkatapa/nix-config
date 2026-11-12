# Shell script context (tupakkatapa house style)

Conventions for bash scripts in any project. The reference script is `~/Workspace/tupakkatapa/nixos-tpm-host-key/packages/tpm-host-key/tpm-host-key.sh`. `mozid/mozid.sh` and `gh-envsync/gh-envsync.sh` predate this idiom (no `say`, four-space indent); align them when they are touched.

## Shebang and strict mode

From `tpm-host-key.sh:1-3`:

```bash
#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit
```

Every script in the projects starts with `#!/usr/bin/env bash` and `set -euo pipefail`. `inherit_errexit` makes command substitutions fail the script too.

## Channel discipline

- **stdout**: results a caller can pipe.
- **stderr**: diagnostics (progress, warnings, errors).
- **exit code**: status.

A script with no pipeable output writes everything to stderr.

## `say` and `die`

One diagnostic helper, with verbose gating. From `tpm-host-key.sh:48-73`, without its header comment:

```bash
verbose=false

say() {
  local message
  local verbose_only=false

  if [[ $1 == "verbose" ]]; then
    verbose_only=true
    shift
  fi

  message="$*"

  if [[ $verbose_only == true ]] && [[ $verbose == false ]]; then
    return
  fi

  if [[ $verbose == true ]]; then
    echo "[$(date '+%H:%M:%S')] $message" >&2
  else
    echo "$message" >&2
  fi
}

die() {
  say "$@"
  exit 1
}
```

- `say "message"` always prints; `say verbose "message"` prints only with `-v`. Verbose mode adds a timestamp.
- Error text carries its own prefix: `die "error: unknown flag: $1"`.
- No separate `info`/`warn`/`err` helpers. A script that never needs verbose output may use the one-line form (`anytui/scripts/check-versions.sh`): `say() { printf '%s\n' "$*" >&2; }`.

## Argument parsing

Shortened from `tpm-host-key.sh:221-259`:

```bash
positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  --force)
    force=true
    shift
    ;;
  -v | --verbose)
    verbose=true
    shift
    ;;
  -h | --help)
    display_usage
    exit 0
    ;;
  --)
    shift
    positional+=("$@")
    break
    ;;
  -*) die "error: unknown flag: $1" ;;
  *)
    positional+=("$1")
    shift
    ;;
  esac
done
```

- Explicit `case`; an unknown flag is an error.
- `--` ends flag parsing; the rest is positional.
- Validate the combination of flags and positionals after the loop, with `die`.

## Usage

Every script has `display_usage` with the sections Usage, Description, Options, Examples (`tpm-host-key.sh`, `mozid/mozid.sh`, `gh-envsync/gh-envsync.sh`):

```bash
display_usage() {
  cat <<USAGE
Usage: <name> [-v] [--force] ARG

Description:
  <one paragraph>

Options:
  -v, --verbose
    Enable verbose output

  -h, --help
    Display this help message and exit

Examples:
  <name> --force value
USAGE
}
```

Exit 0 on `--help`, 1 on bad arguments.

## Safety

- Quote every expansion; use arrays for argument lists.
- Check required tools at startup (`tpm-host-key.sh:279-281`):
  ```bash
  for tool in "${tools[@]}" xxd base64 sha256sum; do
    command -v "$tool" >/dev/null 2>&1 || die "error: $tool not found in PATH"
  done
  ```
- Temporary files go in a `mktemp` directory removed on exit (`tpm-host-key.sh:283`):
  ```bash
  tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
  ```
- Script-wide constants are `readonly`; function variables are `local`.
- No `eval`.
- Functions return through stdout and the exit code; the only globals are script-wide settings such as `$verbose`.

## Packaging

From `nixos-tpm-host-key/packages/tpm-host-key/default.nix`, without `passthru`:

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "tpm-host-key";
  version = "0.2.0";
  src = ./tpm-host-key.sh;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    install -D -m 755 $src $out/bin/${finalAttrs.pname}
    wrapProgram $out/bin/${finalAttrs.pname} \
      --prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
  '';

  meta = {
    description = "OpenSSH ed25519 host key derived from the TPM";
    license = lib.licenses.gpl3Only;
    mainProgram = finalAttrs.pname;
  };
})
```

`buildInputs` lists the runtime tools; `wrapProgram` puts them on the script's `PATH`. `mozid/flake.nix` and `gh-envsync/flake.nix` wrap the same way inline. Test the script as a derivation in `passthru.tests` and list it in the flake's `checks`.

## Lint and format

A project with shell scripts adds both to treefmt (`nixos-tpm-host-key/flake.nix`):

```nix
shellcheck.enable = true;
shfmt.enable = true;
```

The reference script is formatted this way: two-space indent, `case` arms not indented. `# shellcheck disable` follows the global suppression rule in `~/.claude/CLAUDE.md`.
