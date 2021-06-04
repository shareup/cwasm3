#! /usr/bin/env bash

function get_local_tag() {
  cat VERSION 2>/dev/null | tr -d '[:space:]'
}

function get_remote_tag() {
  curl \
    --silent \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/wasm3/wasm3/releases?per_page=1 |
    awk '/"tag_name"\s*:\s*"/' |
    grep -oE "v([0-9]{1,}\.{0,1})+"
}

function replace_wasm3_with_branch() {
  rm -rf .wasm3
  mkdir .wasm3
  pushd .wasm3 >/dev/null

  git clone --depth 1 --branch $1 https://github.com/wasm3/wasm3.git &>/dev/null

  find wasm3/source -regex ".*\.c" -exec cp {} ../Sources/CWasm3/ \;
  find wasm3/source | \
    grep -E "(source/|source/extensions/)(m3|was).*\.h" | \
    xargs -I INPUT_FILE cp INPUT_FILE ../Sources/CWasm3/include/
  rm ../Sources/CWasm3/include/m3.h &>/dev/null # remove this deprecated header
  rm ../Sources/CWasm3/include/m3_api_defs.h &>/dev/null # remove this deprecated header

  popd >/dev/null
}

if [ -z "$1" ]; then
  REMOTE_TAG=$(get_remote_tag)
  LOCAL_TAG=$(get_local_tag)
  if [[ "$REMOTE_TAG" > "$LOCAL_TAG" ]]; then
    echo "$REMOTE_TAG is newer than $LOCAL_TAG"
    echo "Updating to $REMOTE_TAG..."

    replace_wasm3_with_branch $REMOTE_TAG

    echo $REMOTE_TAG >VERSION

    echo "Updated to $REMOTE_TAG"
  else
    echo "$LOCAL_TAG is the most recent version"
  fi
else
  echo "Updating to $1..."

  replace_wasm3_with_branch $1
  rm VERSION &>/dev/null # manually manage Wasm3 versions

  echo "Updated to $1"
fi
