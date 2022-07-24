#! /usr/bin/env bash

set -e

function get_project_dir() {
  SELF=`realpath $0`
  DIR=`dirname $SELF`
  echo ${DIR%/*}
}

function get_version() {
  cat "$(get_project_dir)"/VERSION | sed 's/[\sv]//g'
}

function deletePreviousArtifacts() {
  find . -type f -name 'CWasm3*.xcframework' -exec rm {} +
  find . -type f -name 'CWasm3*.xcframework.zip' -exec rm {} +
  find . -type f -name 'CWasm3*.xcframework.zip.checksum' -exec rm {} +
  rm -rf .archives
}

function buildFramework() {
  xcodebuild archive \
    -project cwasm3.xcodeproj \
    -scheme CWasm3 \
    -destination "$1" \
    -archivePath "$2" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
}

function createXCFramework() {
  xcodebuild \
    -create-xcframework \
    -framework ".archives/CWasm3-iOS.xcarchive/Products/Library/Frameworks/CWasm3.framework" \
    -debug-symbols "$1/.archives/CWasm3-iOS.xcarchive/BCSymbolMaps/9EDFC8DD-15A8-39FB-B396-190B0F458495.bcsymbolmap" \
    -debug-symbols "$1/.archives/CWasm3-iOS.xcarchive/dSYMs/CWasm3.framework.dSYM" \
    -framework ".archives/CWasm3-iOS-Simulator.xcarchive/Products/Library/Frameworks/CWasm3.framework" \
    -debug-symbols "$1/.archives/CWasm3-iOS-Simulator.xcarchive/dSYMs/CWasm3.framework.dSYM" \
    -framework ".archives/CWasm3-macOS-Catalyst.xcarchive/Products/Library/Frameworks/CWasm3.framework" \
    -debug-symbols "$1/.archives/CWasm3-macOS-Catalyst.xcarchive/dSYMs/CWasm3.framework.dSYM" \
    -framework ".archives/CWasm3-macOS.xcarchive/Products/Library/Frameworks/CWasm3.framework" \
    -debug-symbols "$1/.archives/CWasm3-macOS.xcarchive/dSYMs/CWasm3.framework.dSYM" \
    -output CWasm3.xcframework
}

function zipXCFramework() {
  ditto -c -k --sequesterRsrc --keepParent CWasm3.xcframework "$1"
}

function createChecksum() {
  CHECKSUM=`swift package compute-checksum $1`
  
  echo "$CHECKSUM" > "$1.checksum"
  
  echo ""
  echo "🔒 $(swift package compute-checksum $1)"
}

VERSION="$(get_version)"

if [ -z "$VERSION" ]; then
    echo "❌️ Version must be set"
    exit -1
fi

PROJECT_DIR="$(get_project_dir)"
pushd "$PROJECT_DIR" &>/dev/null

deletePreviousArtifacts
mkdir .archives

buildFramework "generic/platform=iOS" ".archives/CWasm3-iOS"
buildFramework "generic/platform=iOS Simulator" ".archives/CWasm3-iOS-Simulator"
buildFramework "generic/platform=macOS,variant=Mac Catalyst" ".archives/CWasm3-macOS-Catalyst"
buildFramework "generic/platform=macOS" ".archives/CWasm3-macOS"
createXCFramework $PROJECT_DIR
ZIP_NAME="CWasm3-$VERSION.xcframework.zip"
zipXCFramework $ZIP_NAME
createChecksum $ZIP_NAME
rm -rf CWasm3.xcframework

popd &>/dev/null
