#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.0.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="${ROOT_DIR}/release-${VERSION}"

SCRIPT_FILE="${ROOT_DIR}/ShillenSilent.lua"
CORE_DIR="${ROOT_DIR}/ShillenSilent_core"
README_FILE="${ROOT_DIR}/README.md"
INSTALL_SCRIPT="${ROOT_DIR}/install_release.bat"

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

if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
  echo "Error: missing install script: ${INSTALL_SCRIPT}" >&2
  exit 1
fi

mkdir -p "${RELEASE_DIR}"
cp -a "${SCRIPT_FILE}" "${RELEASE_DIR}/"
cp -a "${CORE_DIR}" "${RELEASE_DIR}/"
cp -a "${README_FILE}" "${RELEASE_DIR}/"
cp -a "${INSTALL_SCRIPT}" "${RELEASE_DIR}/"

echo "Release created at: ${RELEASE_DIR}"
