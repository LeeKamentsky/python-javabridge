#!/bin/bash
#
# Build python-javabridge on a clean CentOS machine.

set -e
set -x

here=$(dirname "$0")
yum install -y python-setuptools numpy gcc python-devel java-1.7.0-openjdk-devel which
python "$here"/get-pip.py
pip install cython
cd "$here"/..
python setup.py sdist

