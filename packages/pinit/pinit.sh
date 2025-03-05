#!/usr/bin/env bash
# pinit.sh – DRY version

set -o pipefail
trap 'exit 0' SIGINT

# Initial argument values
output_path="$(pwd)"
project_name="$(basename "$(pwd)")"
mode="package"  # Default mode is "package"
lang=""
src_dir="@SRC_DIR@"  # Will be substituted in during the build

display_usage() {
  cat <<USAGE
Usage: pinit [OPTIONS...] LANG

Description:
  Initialize a project environment for a given language.

Arguments:
  LANG
    Supported languages: rust, python, bash, javascript
    Shorthands: rs (for rust), py (for python), sh (for bash), js (for javascript)

Options:
  -o, --output VALUE    Output path for the project (default: current directory)
  -n, --name VALUE      Name of the project (default: parent directory name)
  -m, --mode VALUE      Mode of project initialization (default: package)
                        Supported modes: package, flake
  -h, --help            Show this help message

Examples:
  pinit --output /path/to/dir --name my_rust_project rust --mode flake

USAGE
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -o|--output)
        output_path="$2"
        project_name="$(basename "$output_path")"
        shift 2
        ;;
      -n|--name)
        project_name="$2"
        shift 2
        ;;
      -m|--mode)
        mode="$2"
        shift 2
        ;;
      -h|--help)
        display_usage
        exit 0
        ;;
      *)
        if [ -z "$lang" ]; then
          lang="$1"
          case "$lang" in
            sh) lang="bash" ;;
            py) lang="python" ;;
            rs) lang="rust" ;;
            js) lang="javascript" ;;
          esac
        else
          echo "error: unknown option '$1'"
          display_usage
          exit 1
        fi
        shift
        ;;
    esac
  done
}

# Helper to apply uniform permissions
apply_permissions() {
  find "${output_path}" -type d -exec chmod 755 {} \;
  find "${output_path}" -type f -exec chmod 644 {} \;
}

# Helper to substitute the project name in given file if it exists
substitute_project_name() {
  local file="$1"
  [ -f "${file}" ] && sed -i "s/foobar/${project_name}/g" "${file}"
}

# Common function to copy source files and fix up names/permissions
copy_source_files() {
  if [ ! -d "${src_dir}/${lang}" ]; then
    echo "error: no source files available for ${lang}"
    exit 1
  fi

  cp -vr "${src_dir}/${lang}/." "${output_path}/"

  if [ "${mode}" == "package" ]; then
    rm -f "${output_path}/flake.nix" "${output_path}/module.nix"
    echo 'use nix' > "${output_path}/.envrc"
    chmod 644 "${output_path}/.envrc"
    if [ -f "${output_path}/package.nix" ]; then
      mv "${output_path}/package.nix" "${output_path}/default.nix"
      sed -i "s|./package.nix|./default.nix|g" "${output_path}/shell.nix"
      substitute_project_name "${output_path}/default.nix"
    fi
  elif [ "${mode}" == "flake" ]; then
    rm -f "${output_path}/shell.nix"
    if [ -f "${src_dir}/module.nix" ]; then
      cp -v "${src_dir}/module.nix" "${output_path}/"
    fi
    echo '.direnv/' >> "${output_path}/.gitignore"
    echo 'use flake . --impure --accept-flake-config' > "${output_path}/.envrc"
    chmod 644 "${output_path}/.gitignore" "${output_path}/.envrc"
    substitute_project_name "${output_path}/flake.nix"
    substitute_project_name "${output_path}/module.nix"
    substitute_project_name "${output_path}/package.nix"
  fi

  apply_permissions
}

create_project() {
  mkdir -p "${output_path}"
  chmod 755 "${output_path}"

  # Copy the source files and adjust common settings
  copy_source_files

  # Initialize the project based on language
  case "$lang" in
    rust)
      cargo init --name "${project_name}" "${output_path}" --vcs "none"
      ( cd "${output_path}" && cargo build )
      ;;
    javascript)
      ( cd "${output_path}" && npm init -y )
      ( cd "${output_path}" && npm pkg set bin."${project_name}"=app.js )
      chmod +x "${output_path}/app.js"
      ( cd "${output_path}" && yarn add express && yarn install )
      ;;
    bash)
      ( cd "${output_path}" && chmod +x main.sh )
      ;;
    python)
      # You can add Python-specific initialization here if needed
      ;;
    *)
      echo "error: unsupported language '${lang}'"
      exit 1
      ;;
  esac

  # Automatically allow the .envrc file if direnv is installed
  command -v direnv >/dev/null 2>&1 && direnv allow "${output_path}"

  # For flake mode, initialize a git repository
  if [ "$mode" == "flake" ]; then
    nix flake lock path:"${output_path}"
    git init "${output_path}" --initial-branch=main
    git -C "${output_path}" add -A
    git -C "${output_path}" commit -m "init"
  fi
}

main() {
  parse_arguments "$@"

  if [ -z "$lang" ]; then
    echo "error: no language specified"
    display_usage
    exit 1
  fi

  case "$lang" in
    rust|python|bash|javascript)
      create_project
      ;;
    *)
      echo "error: unsupported language '${lang}'"
      echo "supported languages: rust, python, bash, javascript"
      exit 1
      ;;
  esac
}

main "$@"
