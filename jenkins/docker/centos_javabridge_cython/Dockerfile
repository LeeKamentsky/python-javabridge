# Build on centos_javabridge by installing Cython.
# Cython is needed for building the Javabridge but not for testing it.

FROM centos_javabridge
MAINTAINER Vebjorn Ljosa, ljosa@broad.mit.edu

RUN yum install -y git
# Copied from https://raw.github.com/pypa/pip/master/contrib/get-pip.py
ADD get-pip.py /tmp/get-pip.py
RUN python /tmp/get-pip.py
RUN pip install cython
