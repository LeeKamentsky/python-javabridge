#!/bin/bash
#
# Test the python-javabridge source distribution on the
# centos_javabridge Docker image.
#
# Jenkins will run docker to spn up a container based on the
# centos_javabridge image, mount the "dist" subdirectory of the
# Jenkins workspace as a volume, then run this script inside the
# container.
#
# This script installs the source distribution and runs the unit
# tests.

set -e
set -x

mkdir /javabridge
cd /javabridge
tar xvzf /dist/*.tar.gz
cd *
python setup.py develop
python setup.py build_clib
python setup.py nosetests
