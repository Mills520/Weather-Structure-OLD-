#!/usr/bin/env bash
set -euo pipefail

# If invoked by a non-bash shell, re-exec with bash.
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
TOOLS_DIR="$ROOT_DIR/.tools"
GRADLE_VERSION="8.14.3"
GRADLE_HOME="$TOOLS_DIR/gradle-${GRADLE_VERSION}"
GRADLE_BIN="$GRADLE_HOME/bin/gradle"

# Build targets. Fabric tracks 1.21.1; Forge stops at 1.20.1, the last Minecraft
# version with a stable MinecraftForge line (newer versions moved to NeoForge).
FABRIC_MC="1.21.1"
FABRIC_LOADER="0.16.10"
FABRIC_API="0.115.1+1.21.1"
FORGE_MC="1.20.1"
FORGE_VERSION="47.3.0"

mkdir -p "$DIST_DIR" "$TOOLS_DIR"

# Echoes the gradle command to use on stdout; progress messages go to stderr so
# they do not get captured by the caller.
ensure_gradle() {
  if command -v gradle >/dev/null 2>&1; then
    local current major
    current="$(gradle -v 2>/dev/null | awk '/^Gradle /{print $2; exit}' || true)"
    major="${current%%.*}"
    if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 8 )); then
      echo "Using system Gradle $current" >&2
      command -v gradle
      return 0
    fi
  fi

  if [[ ! -x "$GRADLE_BIN" ]]; then
    local zip="$TOOLS_DIR/gradle-${GRADLE_VERSION}-bin.zip"
    echo "System Gradle is missing or older than 8. Downloading Gradle ${GRADLE_VERSION}..." >&2
    curl -fL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o "$zip"
    unzip -q -o "$zip" -d "$TOOLS_DIR"
  fi

  echo "$GRADLE_BIN"
}

GRADLE_CMD="$(ensure_gradle)"

echo "==> Building Fabric $FABRIC_MC"
(
  cd "$ROOT_DIR"
  "$GRADLE_CMD" -p fabric clean build \
    -Pminecraft_version="$FABRIC_MC" \
    -Pfabric_loader_version="$FABRIC_LOADER" \
    -Pfabric_api_version="$FABRIC_API"
)
mkdir -p "$DIST_DIR/fabric/$FABRIC_MC"
cp "$ROOT_DIR/fabric/build/libs"/*.jar "$DIST_DIR/fabric/$FABRIC_MC/"

echo "==> Building Forge $FORGE_MC"
(
  cd "$ROOT_DIR"
  "$GRADLE_CMD" -p forge clean build \
    -Pminecraft_version="$FORGE_MC" \
    -Pforge_version="$FORGE_VERSION"
)
mkdir -p "$DIST_DIR/forge/$FORGE_MC"
cp "$ROOT_DIR/forge/build/libs"/*.jar "$DIST_DIR/forge/$FORGE_MC/"

echo "Built artifacts are in $DIST_DIR"
