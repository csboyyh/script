#!/bin/bash

export JAVA_HOME=/usr/java/jdk1.6.0_29
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
export CLASSPATH=$CLASSPATH:.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib

ccache -M 50G
