#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Generate BuildInfo.swift for local development

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR/..}"
OUTPUT_DIR="$PROJECT_DIR/Core/Generated"
OUTPUT_FILE="$OUTPUT_DIR/BuildInfo.swift"

mkdir -p "$OUTPUT_DIR"

COMMIT_HASH=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
DIRTY_STATE=$(git -C "$PROJECT_DIR" diff --quiet 2>/dev/null && echo "false" || echo "true")
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$OUTPUT_FILE" << EOF
// SPDX-License-Identifier: Apache-2.0
// Auto-generated - DO NOT EDIT

import Foundation

public enum BuildInfo {
    public static let commitHash = "$COMMIT_HASH"
    public static let isDirty = $DIRTY_STATE
    public static let buildTimestamp = "$BUILD_TIMESTAMP"
}
EOF

echo "Generated $OUTPUT_FILE (commit: ${COMMIT_HASH:0:7}, dirty: $DIRTY_STATE)"
