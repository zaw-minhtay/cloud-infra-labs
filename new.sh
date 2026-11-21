#!/usr/bin/env bash
# Create a new lab or architecture from the templates, with the next number.
#
# Usage:
#   ./new.sh lab  <category> <name>    e.g. ./new.sh lab ci-cd gitops-argocd-pipeline
#   ./new.sh arch <name>               e.g. ./new.sh arch gitops-cicd-pipeline
#
# Names: lowercase letters, numbers and hyphens only.
set -euo pipefail
cd "$(dirname "$0")"

# Allowed lab categories. Add a new one here (and to the README) when you need it.
CATEGORIES="aws terraform docker kubernetes ci-cd linux"

usage() {
  sed -n '4,6p' "$0" | sed 's/^# *//'
  exit 1
}

check_name() {
  [[ "$1" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || {
    echo "Error: '$1' must be lowercase letters, numbers and hyphens (e.g. gitops-argocd-pipeline)."
    exit 1
  }
}

# Next free two-digit number inside a folder: 01, 02, ...
next_number() {
  local last
  last=$(find "$1" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9]-*' 2>/dev/null \
    | sed -E 's#.*/([0-9]{2})-.*#\1#' | sort | tail -1)
  printf '%02d' $((10#${last:-0} + 1))
}

kind=${1:-}
case "$kind" in
  lab)
    [ $# -eq 3 ] || usage
    category=$2 name=$3
    [[ " $CATEGORIES " == *" $category "* ]] || {
      echo "Error: unknown category '$category'. Use one of: $CATEGORIES"
      exit 1
    }
    check_name "$name"
    parent="labs/$category"
    mkdir -p "$parent"
    num=$(next_number "$parent")
    dir="$parent/$num-$name"
    mkdir "$dir"
    sed -e "1s/NN/$num/" -e "s/^\*\*Category:\*\* CATEGORY/**Category:** $category/" \
      templates/LAB_TEMPLATE.md > "$dir/README.md"
    ;;
  arch)
    [ $# -eq 2 ] || usage
    name=$2
    check_name "$name"
    parent="architectures"
    num=$(next_number "$parent")
    dir="$parent/$num-$name"
    mkdir "$dir"
    sed -e "1s/NN/$num/" templates/ARCHITECTURE_TEMPLATE.md > "$dir/README.md"
    ;;
  *)
    usage
    ;;
esac

echo "Created $dir/README.md"
echo "Next: fill in the README, add diagram.png, and add a row to the table in README.md."
