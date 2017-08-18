#!/bin/bash
rm -rf /usr/local/tomcat/webapps/*
ln -s /opt/guacamole/guacamole.war /usr/local/tomcat/webapps/ROOT.war
exec /opt/guacamole/bin/start.sh
