#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.0.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="${ROOT_DIR}/release-${VERSION}"
SRC_DIR="${RELEASE_DIR}/src"

SCRIPT_FILE="${ROOT_DIR}/ShillenSilent.lua"
CORE_DIR="${ROOT_DIR}/ShillenSilent_core"
README_FILE="${ROOT_DIR}/README.md"

if [[ -d "${RELEASE_DIR}" ]]; then
  echo "Error: release directory already exists: ${RELEASE_DIR}" >&2
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

mkdir -p "${SRC_DIR}"
cp -a "${SCRIPT_FILE}" "${SRC_DIR}/"
cp -a "${CORE_DIR}" "${SRC_DIR}/"
cp -a "${README_FILE}" "${RELEASE_DIR}/"

echo "Release created at: ${RELEASE_DIR}"
