#!/bin/bash

set -e

# SwiftGen 경로 찾기
if which swiftgen >/dev/null; then
    SWIFTGEN=$(which swiftgen)
else
    echo "warning: SwiftGen not installed, download from https://github.com/SwiftGen/SwiftGen"
    exit 0
fi

# SwiftGen 실행
cd "${SRCROOT}"
"${SWIFTGEN}" config run --config swiftgen.yml

echo "SwiftGen: Code generation completed successfully"
