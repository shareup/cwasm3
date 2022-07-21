#!/usr/bin/env bash

set -e

SELF=`realpath $0`
DIR=`dirname $SELF`
PROJECT_DIR=`echo ${DIR%/*}`
VENDOR_CWASM3_DIR="${PROJECT_DIR}/vendor/cwasm3"
VERSION=`cat ${PROJECT_DIR}/VERSION | sed 's/[\sv]//g'`

if [ -z "$VERSION" ]; then
    echo "❗️ Version must be set"
    exit -1
fi

pushd "$VENDOR_CWASM3_DIR" &>/dev/null

swift create-xcframework \
  --output "${PROJECT_DIR}/framework" \
  --platform ios \
  --platform macos \
  --platform maccatalyst \
  --xc-setting APPLICATION_EXTENSION_API_ONLY=YES \
  --xc-setting d_m3MaxDuplicateFunctionImpl=10 \
  --xc-setting MARKETING_VERSION=${VERSION} \
  --zip-version ${VERSION} \
  --zip

popd &>/dev/null
