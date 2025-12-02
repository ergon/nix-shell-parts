#!/usr/bin/env bash

set -euo pipefail

validate=true
showDebugOutput=false
listFiles=false
packageFilesJSON="$(mktemp)"
while [[ $# -gt 0 ]]; do
  case "$1" in
  --help)
    renovate --help
    echo ""
    echo "Preview Options:"
    echo "  --debug                                      Prints the renovate debug log to stdout"
    echo "  --package-files <file>                       Stores the captured packageFiles JSON file to <file> for further analysis"
    echo "  --list-files                                 Include the files in which the version will be modified in the report"
    echo "  --no-validate                                Do neither validate the configuration files nor check if such files exist before running renovate"
    exit 0
    ;;
  --package-files)
    packageFilesJSON=$2
    shift 2
    ;;
  --list-files)
    listFiles=true
    shift
    ;;
  --debug)
    showDebugOutput=true
    shift
    ;;
  --no-validate)
    validate=false
    shift
    ;;
  --)
    shift
    POSITIONAL_ARGS+=("$@")
    break
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

if [ $validate == true ]; then
  set +e
  validationOutput=$(renovate-config-validator)
  ret=$?
  set -e

  if [ $ret -ne 0 ]; then
    echo -e "$validationOutput"
    echo "ERROR: Validation failed" >&2
    exit $ret
  fi

  if [ $showDebugOutput == true ] || [ $ret -ne 0 ]; then
    echo -e "$validationOutput"
  fi

  echo "$validationOutput" | grep -q '^ INFO: Validating' || {
    echo "ERROR: No valid renovate config file found. Create one or run the renovate-preview with --no-validate" >&2
    echo "See https://docs.renovatebot.com/getting-started/installing-onboarding/#configuration-location" >&2
    exit 1
  }
fi

set +e
renovateOutput=$(
  LOG_LEVEL=DEBUG renovate --onboarding=false --platform=local "${POSITIONAL_ARGS[@]}"
)
ret=$?
set -e

if [ $showDebugOutput == true ] || [ $ret -ne 0 ]; then
  echo -e "$renovateOutput"
fi

if [ $ret -ne 0 ]; then
  exit $ret
fi

# Renovate outputs extensive debug information, including package files with version and update details.
# The first sed extracts only the lines containing updates (yielding nearly valid JSON),
# the second sed fixes the JSON by replacing "config: {" with "{",
# and jq then formats and sorts the output.
# The resulting JSON is saved for summary generation (and maybe further analysis).
echo "$renovateOutput" |
  sed -n '/DEBUG: packageFiles with updates (repository=local)/,/DEBUG: detectSemanticCommits() (repository=local)/{//!p;}' |
  sed '1s/.*/{/' >"$packageFilesJSON"

if [[ $(<"$packageFilesJSON") == "{" ]]; then
  echo "No packageFiles found"
  rm "$packageFilesJSON"
  exit 0
fi

jq --sort-keys '.' "${packageFilesJSON}" >"${packageFilesJSON}.sorted" && mv "${packageFilesJSON}.sorted" "$packageFilesJSON"
jq --argjson showFiles $listFiles -r -f "$RENOVATE_PREVIEW_JQ" "$packageFilesJSON"