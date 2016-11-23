#!/bin/sh
PUBSPEC=$1
shift
PUB=/usr/lib/dart/bin/pub
#HOME="/home/`whoami`"
#shift
#echo -- $*
#POLYMERIZE_DEV_HOME=$HOME/dart/devc_builder
#/usr/bin/dart  $POLYMERIZE_DEV_HOME/bin/polymerize.dart $*
cd `dirname $PUBSPEC`
$PUB get
$PUB run polymerize:polymerize $*
#$HOME/.pub-cache/bin/polymerize $*


exit 0
