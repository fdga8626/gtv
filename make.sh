#!/bin/bash

set -e

WORKSPACE=$(dirname $(readlink -f $0))
GTV=${WORKSPACE}/src/git-tag-version
BUILD_DIR=${WORKSPACE}/build
TEST_DIR=${WORKSPACE}/test
TEST_RESULTS=${BUILD_DIR}/test.results
cd ${WORKSPACE}

function cmd_help {
  echo "$0 COMMAND

COMMAND
  help    print this help text
  test    run tests, returns 0 on success, test results in \"TEST_RESULTS\"
  tag     create a new patch version (with strict mode)
  build   create a release artifact in \"${BUILD_DIR}/git-tag-version\"
"
}

function cmd_clean {
  echo -e "\n## Cleaning up"
  rm -rfv ${BUILD_DIR}
}

function cmd_test {
  echo -e "\n## Executing tests"
  mkdir -p ${WORKSPACE}/build
  # make bats available and execute tests
  git clone https://github.com/sstephenson/bats.git &> /dev/null || : # do not abort if clone exists
  PATH=$PATH:${WORKSPACE}/bats/bin
  date > ${TEST_RESULTS}
  env GTV="${GTV}" bats ${TEST_DIR}/*.bats | tee ${TEST_RESULTS}
  echo "Test results saved to ${TEST_RESULTS}"
}

function cmd_tag {
  echo -e "\n## Tagging version"
  ${GTV} new patch --strict
}

# build the gtv release artifact, expects version string number as first argument, auto generates it otherwise
function cmd_build {
  echo -e "\n## Building artifact"
  mkdir -p ${WORKSPACE}/build
  cp -f ${WORKSPACE}/src/git-tag-version ${BUILD_DIR}/

  if [ -n "$1" ]; then
    VERSION=$1
  else
    SUFFIX="${TRAVIS_BUILD_NUMBER:-local}"
    VERSION="$(bash ${WORKSPACE}/src/git-tag-version)-${SUFFIX}"
  fi
  sed -e "s/^\(GTV_VERSION=\).*$/\1\"$VERSION\"/g" -i ${BUILD_DIR}/git-tag-version
  echo "Version $VERSION"
  echo "Provided at ${BUILD_DIR}/git-tag-version"
}

case "$1" in
  "clean")
    cmd_clean
    ;;
  "test")
    cmd_test
    ;;
  "tag")
    cmd_tag
    ;;
  "build")
    cmd_build $2
    ;;
  "help")
    cmd_help
    ;;
  *)
    cmd_clean
    cmd_test
    cmd_build $2
    ;;
esac