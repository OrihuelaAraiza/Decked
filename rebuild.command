#!/bin/bash
cd "$(dirname "$0")"
xcodebuild clean -project Decked.xcodeproj -scheme Decked
xcodebuild build -project Decked.xcodeproj -scheme Decked -destination 'generic/platform=iOS'
