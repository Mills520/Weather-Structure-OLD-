#!/usr/bin/env bash
set -euo pipefail

# If invoked by a non-bash shell, re-exec with bash.
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
TOOLS_DIR="$ROOT_DIR/.tools"

# Build targets.
FABRIC_MC="1.21.1"
FABRIC_LOADER="0.16.10"
FABRIC_API="0.115.1+1.21.1"

# Forge targets as "minecraft:forge". Minecraft 1.20.5+ is compiled against
# Java 21 and earlier releases against Java 17; forge/build.gradle picks the
# matching toolchain from the version, so both JDKs must be installed to build
# every row here.
FORGE_TARGETS=(
  "1.20.1:47.3.0"
  "1.21.1:52.1.0"
)

# Each loader pins its own Gradle, matching .github/workflows/build-jars.yml.
# Fabric Loom 1.7.x calls the incubating Gradle API
# Problems.forNamespace(String), which exists only in Gradle 8.6-8.12 and was
# removed in later releases; on Gradle 8.13+ applying the plugin fails with
# NoSuchMethodError. ForgeGradle 6 is happy on current Gradle.
FABRIC_GRADLE="8.10.2"
FORGE_GRADLE="8.14.3"

mkdir -p "$DIST_DIR" "$TOOLS_DIR"

# ensure_gradle <version> -> echoes a gradle executable for exactly that version.
# The system gradle is reused only on an exact version match, because these
# builds are sensitive to the Gradle version; otherwise the version is
# downloaded into .tools/. Progress messages go to stderr so they are not
# captured by the caller.
ensure_gradle() {
  local want="$1"
  local home="$TOOLS_DIR/gradle-${want}"
  local bin="$home/bin/gradle"

  if command -v gradle >/dev/null 2>&1; then
    local current
    current="$(gradle -v 2>/dev/null | awk '/^Gradle /{print $2; exit}' || true)"
    if [[ "$current" == "$want" ]]; then
      echo "Using system Gradle $current" >&2
      command -v gradle
      return 0
    fi
  fi

  if [[ ! -x "$bin" ]]; then
    local zip="$TOOLS_DIR/gradle-${want}-bin.zip"
    echo "Downloading Gradle ${want}..." >&2
    curl -fL "https://services.gradle.org/distributions/gradle-${want}-bin.zip" -o "$zip"
    unzip -q -o "$zip" -d "$TOOLS_DIR"
  fi

  echo "$bin"
}

echo "==> Building Fabric $FABRIC_MC (Gradle $FABRIC_GRADLE)"
FABRIC_GRADLE_CMD="$(ensure_gradle "$FABRIC_GRADLE")"
(
  cd "$ROOT_DIR"
  "$FABRIC_GRADLE_CMD" -p fabric clean build \
    -Pminecraft_version="$FABRIC_MC" \
    -Pfabric_loader_version="$FABRIC_LOADER" \
    -Pfabric_api_version="$FABRIC_API"
)
mkdir -p "$DIST_DIR/fabric/$FABRIC_MC"
cp "$ROOT_DIR/fabric/build/libs"/*.jar "$DIST_DIR/fabric/$FABRIC_MC/"

FORGE_GRADLE_CMD="$(ensure_gradle "$FORGE_GRADLE")"
for target in "${FORGE_TARGETS[@]}"; do
  IFS=':' read -r forge_mc forge_version <<< "$target"
  echo "==> Building Forge $forge_mc (Gradle $FORGE_GRADLE)"
  (
    cd "$ROOT_DIR"
    "$FORGE_GRADLE_CMD" -p forge clean build \
      -Pminecraft_version="$forge_mc" \
      -Pforge_version="$forge_version"
  )
  mkdir -p "$DIST_DIR/forge/$forge_mc"
  cp "$ROOT_DIR/forge/build/libs"/*.jar "$DIST_DIR/forge/$forge_mc/"
done

echo "Built artifacts are in $DIST_DIR"
