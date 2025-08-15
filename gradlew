#!/usr/bin/env sh
export GRADLE_OPTS="${GRADLE_OPTS} -Dorg.gradle.jvmargs='-Xmx4g -Dfile.encoding=UTF-8'"
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/gradle/wrapper/gradle-wrapper.jar" "$@"
