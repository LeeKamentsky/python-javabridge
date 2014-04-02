#!/bin/bash
#
# Test the python-javabridge source distribution on the
# centos_javabridge Docker image.
#
# Jenkins will run docker to spn up a container based on the
# centos_javabridge image, then run this script with the source
# distribution .tar.gz on standard input.
#
# This script installs the source distribution and runs the unit
# tests.

set -e
set -x

cat > /tmp/python-javabridge.tar.gz
mkdir /javabridge
cd /javabridge
tar xvzf /tmp/python-javabridge.tar.gz
cd *
python setup.py develop
python setup.py nosetests

