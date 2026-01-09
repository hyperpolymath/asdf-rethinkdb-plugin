#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

TOOL_NAME="rethinkdb"
BINARY_NAME="rethinkdb"

fail() { echo -e "\e[31mFail:\e[m $*" >&2; exit 1; }

list_all_versions() {
  local curl_opts=(-sL)
  [[ -n "${GITHUB_TOKEN:-}" ]] && curl_opts+=(-H "Authorization: token $GITHUB_TOKEN")
  curl "${curl_opts[@]}" "https://api.github.com/repos/rethinkdb/rethinkdb/tags" 2>/dev/null | \
    grep -o '"name": "v[^"]*"' | sed 's/"name": "v//' | sed 's/"$//' | sort -V
}

download_release() {
  local version="$1" download_path="$2"
  local url="https://download.rethinkdb.com/repository/raw/dist/rethinkdb-${version}.tgz"

  echo "Downloading RethinkDB $version..."
  mkdir -p "$download_path"
  curl -fsSL "$url" -o "$download_path/rethinkdb.tgz" || fail "Download failed"
  tar -xzf "$download_path/rethinkdb.tgz" -C "$download_path" --strip-components=1
  rm -f "$download_path/rethinkdb.tgz"
}

install_version() {
  local install_type="$1" version="$2" install_path="$3"

  cd "$ASDF_DOWNLOAD_PATH"
  ./configure --prefix="$install_path" --allow-fetch || fail "Configure failed"
  make -j"$(nproc)" || fail "Build failed"
  make install || fail "Install failed"
}
