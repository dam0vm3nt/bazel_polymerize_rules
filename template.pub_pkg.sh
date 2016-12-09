#!/bin/bash
PACKAGE_NAME=$1
shift
PACKAGE_VERSION=$1
shift

mkdir -p  "${base_dir}"
cd "${base_dir}"
(
cat >pubspec.yaml <<END
name: ${PACKAGE_NAME}_pub
dependencies:
 $PACKAGE_NAME: "$PACKAGE_VERSION"
END

OVERRIDES="${overrides}"

if [ -n "$OVERRIDES" ] ; then
  echo USING OVERRIDES: ${OVERRIDES}
  SOURCE_ARGS="--source path ${OVERRIDES}"
else
  SOURCE_ARGS="${PACKAGE_NAME} ${PACKAGE_VERSION}"
fi


# Pub getting to fill the cache and build `.packages`
PUB_HOSTED_URL="${pub_host}" PUB_CACHE="${cache_dir}" /usr/lib/dart/bin/pub global activate ${SOURCE_ARGS}
) > ${base_dir}/log 2>&1
