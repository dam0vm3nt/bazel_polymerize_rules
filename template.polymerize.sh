#!/bin/sh
#echo ARGUMENTS : $*
/usr/bin/dart --packages=${base_dir}/.packages ${base_dir}/bin/polymerize.dart $*
