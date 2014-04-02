#!/bin/bash
#
# Build python-javabridge on the centos_javabridge Docker image.
#
# Jenkins will run docker to spin up a container based on the
# centos_javabridge image, mount the Jenkins workspace as a volume,
# then run this script inside the container.

set -e
set -x

here=$(dirname "$0")
yum install -y python-setuptools numpy gcc python-devel java-1.7.0-openjdk-devel which
python "$here"/get-pip.py
pip install cython
cd "$here"/..
python setup.py sdist
