#!/bin/bash

echo PATH = $PATH
which pub
cd "${base_dir}"
echo ABOUT TO PUBBBBBB!!!! IN "${base_dir}"
PUB_CACHE="${cache_dir}" /usr/lib/dart/bin/pub get
echo PUBBBEDDDDDDDD!!!!
