#!/bin/bash
# Tests the default ROUGE configuration.
# exit if anything returns failure
set -e

TMP_LOCATION=/tmp/rogue-cookbook
rm -rf $TMP_LOCATION
git clone --depth=1 --branch=master https://github.com/ROGUE-JCTD/rogue-cookbook.git $TMP_LOCATION
rspec $TMP_LOCATION/test/integration/default/serverspec
