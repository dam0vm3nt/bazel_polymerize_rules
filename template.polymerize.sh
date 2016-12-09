#!/bin/sh
#echo ARGUMENTS : $*
#/usr/bin/dart --packages=${base_dir}/.packages package:polymerize/polymerize.dart $*
PUB_CACHE=${cache_dir}
PATH=$PATH:/usr/lib/dart/bin
export PATH PUB_CACHE
${cache_dir}/bin/polymerize $*
