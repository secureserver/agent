#! /bin/sh
### BEGIN INIT INFO
# Provides:          secureserver
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts the secureserver agent.
### END INIT INFO

# Author: secureserver.io

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="secureserver agent"
NAME=secureserver-agent
DAEMON=/opt/secureserver-agent/embedded/secureserver-agent
DAEMON_ARGS=""
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME
USER=secureserver
GROUP=secureserver

