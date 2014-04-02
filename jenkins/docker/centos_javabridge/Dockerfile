# Defines a docker image based on CentOS that includes everything that
# is required to either build the Javabridge or to install the source
# distribution and run the unit tests.

FROM centos
MAINTAINER Vebjorn Ljosa, ljosa@broad.mit.edu
RUN yum install -y python-setuptools numpy gcc python-devel java-1.7.0-openjdk-devel which

# Copied from https://raw.github.com/pypa/pip/master/contrib/get-pip.py
ADD get-pip.py /tmp/get-pip.py
RUN python /tmp/get-pip.py
RUN pip install cython

