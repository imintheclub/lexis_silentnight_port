#!/usr/bin/env bash
set -euo pipefail

RAW_VERSION="${1:-0.0.0}"
if [[ "${RAW_VERSION}" == v* ]]; then
  VERSION="${RAW_VERSION}"
else
  VERSION="v${RAW_VERSION}"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="${ROOT_DIR}/release-${VERSION}"
SRC_DIR="${RELEASE_DIR}/src"
ZIP_FILE="${RELEASE_DIR}/ShillenSilent-${VERSION}.zip"
SOURCE_ROOT="${ROOT_DIR}/src"

SCRIPT_FILE="${SOURCE_ROOT}/ShillenSilent.lua"
CORE_DIR="${SOURCE_ROOT}/ShillenSilent_core"
README_FILE="${ROOT_DIR}/README.md"

if [[ -d "${RELEASE_DIR}" ]]; then
  echo "Error: release directory already exists: ${RELEASE_DIR}" >&2
  exit 1
fi

if [[ ! -d "${SOURCE_ROOT}" ]]; then
  echo "Error: missing source root directory: ${SOURCE_ROOT}" >&2
  exit 1
fi

if [[ ! -f "${SCRIPT_FILE}" ]]; then
  echo "Error: missing script file: ${SCRIPT_FILE}" >&2
  exit 1
fi

if [[ ! -d "${CORE_DIR}" ]]; then
  echo "Error: missing core directory: ${CORE_DIR}" >&2
  exit 1
fi

if [[ ! -f "${README_FILE}" ]]; then
  echo "Error: missing README file: ${README_FILE}" >&2
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: required command not found: zip" >&2
  exit 1
fi

mkdir -p "${SRC_DIR}"
cp -a "${SCRIPT_FILE}" "${SRC_DIR}/"
cp -a "${CORE_DIR}" "${SRC_DIR}/"
cp -a "${README_FILE}" "${RELEASE_DIR}/"

(
  cd "${RELEASE_DIR}"
  zip -r "ShillenSilent-${VERSION}.zip" "src" "README.md" >/dev/null
)

echo "Release created at: ${RELEASE_DIR}"
echo "Release zip created at: ${ZIP_FILE}"
