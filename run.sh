#!/bin/bash
# The MIT License (MIT)
#
# Copyright (c) 2014 Gluu
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

GLUU_VERSION=3.0.2


detect_os() {
        OS_VERSION_FILE_1=/opt/gluu-server-$GLUU_VERSION/etc/redhat-release
        OS_VERSION_FILE_2=/opt/gluu-server-$GLUU_VERSION/etc/os-release
        if [ -f $OS_VERSION_FILE_1 ]; then
                MAJOR_VERSION="`awk '{print $3}' $OS_VERSION_FILE_1 |cut -d '.' -f1`"
                GLUU_OS="`awk '{print $1}' $OS_VERSION_FILE_1`"
        elif [ -f $OS_VERSION_FILE_2 ]; then
                MAJOR_VERSION="`grep VERSION_ID $OS_VERSION_FILE_2 |cut -d '=' -f2|tr -d '"'`"
                GLUU_OS="`grep "^NAME" $OS_VERSION_FILE_2 |cut -d '=' -f2|tr -d '"'`"
        fi
        echo "$GLUU_OS $MAJOR_VERSION"
}

DETECTED_OS=`detect_os`

if [[ $DETECTED_OS == "Ubuntu 14.04" || $DETECTED_OS == "Ubuntu 16.04" || $DETECTED_OS == "Debian GNU/Linux 8" ]]; then

### BEGIN INIT INFO
# Provides:          gluu-server
# Required-Start:       $all
# Required-Stop:        $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: This shell script takes care of starting and stopping
#		     gluu-server (the Gluu Chroot Server)
# Description:       Gluu server chroot environment.
#
#
### END INIT INFO


	PATH=/sbin:/usr/sbin:/bin:/usr/bin

	. /lib/init/vars.sh
	. /lib/lsb/init-functions

	APACHE="apache2"

        if [[ $DETECTED_OS == "Debian GNU/Linux 8" ]]; then
                RESOLV_CONF="/etc/resolv.conf"
        else
                RESOLV_CONF="/run/resolvconf/resolv.conf"
        fi

	LOCK_PATH="/var/lock"
else
#
#       /etc/rc.d/init.d/gluu-server
# gluu-server  This shell script takes care of starting and stopping
#               gluu-server (the Gluu Chroot Server)
#
# chkconfig: 2345 99 02
# description: Gluu server chroot environment.

# Source function library.

	. /etc/init.d/functions
	APACHE="httpd"
	RESOLV_CONF="/etc/resolv.conf"
	LOCK_PATH="/var/lock/subsys"
fi

CHROOT_DIR=/opt/gluu-server-$GLUU_VERSION
PIDFILE=/var/run/gluu-server-$GLUU_VERSION.pid

STAT=(`df -aP |grep \/opt\/gluu-server-$GLUU_VERSION\/ | awk '{ print $6 }' | grep -Eohw 'proc|lo|pts|modules|dev'`)

start() {
	STAT=(`df -aP |grep \/opt\/gluu-server-$GLUU_VERSION\/ | awk '{ print $6 }' | grep -Eohw 'proc|lo|pts|modules|dev'`)
	PORTS=`netstat -tunpl | awk '{ print $4 }' |grep -Eohw ':(80|443|8080|8081|8082|8083|8084|8085|8086|8090|1389|1689|11211)'`
	if [ -f $PIDFILE ] && [ ${#STAT[@]} = "6" ]; then
		PID=`cat $PIDFILE`
                echo "gluu-server-$GLUU_VERSION is already running"
                exit 2
        elif [ -f $PIDFILE ] || [ "$STAT" != "" ]; then
		echo -e "ERROR: Can't start gluu server.\nHINT: Please manually remove $PIDFILE and unmount chroot container by running\nrm -f $PIDFILE\ndf -aP | grep gluu-server-$GLUU_VERSION | awk '{print \$6}' | xargs -I {} umount -l {}"
                exit 2
	elif [ "$PORTS" != "" ]; then
		echo "Port address(es) $PORTS already in use,"
		echo "Please stop the service(s) listening on one of $PORTS ports and execute /etc/init.d/gluu-server-$GLUU_VERSION start"
		exit 2
	else
 		echo "Starting Gluu server, please wait..."

                if [ -f $RESOLV_CONF ]; then
                        cp --parents -f $RESOLV_CONF /opt/gluu-server-$GLUU_VERSION/
                fi

		/bin/mount /dev                    /opt/gluu-server-$GLUU_VERSION/dev -o bind
		/bin/mount /proc                   /opt/gluu-server-$GLUU_VERSION/proc -t proc -o defaults,noatime
		/bin/mount /sys/class/net/lo       /opt/gluu-server-$GLUU_VERSION/sys/class/net/lo -t sysfs -o defaults
		/bin/mount /lib/modules            /opt/gluu-server-$GLUU_VERSION/lib/modules -o bind

                if [[ $DETECTED_OS == "Ubuntu 14.04" || $DETECTED_OS == "Ubuntu 16.04" || $DETECTED_OS == "Debian GNU/Linux 8" ]]; then
			/bin/mount /dev/pts                /opt/gluu-server-$GLUU_VERSION/dev/pts -t devpts -o gid=5,mode=620
                	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c '/bin/hostname -b -F /etc/hostname' > /dev/null 2>&1
        		sleep 2
                	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c '/etc/init.d/rc 3' > /dev/null 2>&1 \
			&& echo "started" > $PIDFILE  || failure $"Chroot start"
                	RETVAL=$?
                	echo
                	[ $RETVAL -eq 0 ] && touch $LOCK_PATH/gluu-server-$GLUU_VERSION
                	return $RETVAL
		else
			/bin/mount /dev/pts                /opt/gluu-server-$GLUU_VERSION/dev/pts -t devpts -o gid=5,mode=62
			/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c '/etc/rc.d/rc.sysinit' > /dev/null 2>&1
                	sleep 2
                	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c '/etc/rc.d/rc 3' > /dev/null 2>&1 \
                	&& echo "started" > $PIDFILE  || failure $"Chroot start"
                	RETVAL=$?
                	echo
                	[ $RETVAL -eq 0 ] && touch $LOCK_PATH/gluu-server-$GLUU_VERSION
			return $RETVAL
		fi
        fi
}

stopGenericService() {
    	serviceName=$1
    	serviceDescription=$2

    	serviceFile="/opt/gluu-server-$GLUU_VERSION/etc/init.d/$serviceName"
    	serviceStatusCheck=$(echo "ps aux | grep $serviceName | grep -v grep")
    	serviceStopCommand=$(echo "service $serviceName stop")

	if [[ -L $serviceFile || -x $serviceFile ]] && [ "`ps aux | grep $serviceName | grep -v grep | grep -i gluu`"  != "" ]; then
             	echo "Stopping $serviceDescription..."
	    	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c 'service $0 stop' -- $serviceName > /dev/null 2>&1

		if [ "`ps aux | grep $serviceName | grep -v grep | grep -i gluu`"  != "" ]; then
                   	echo "Failed"
                else
                   	echo "OK"
                fi
	fi
}

stop() {
        if [ ! -f $PIDFILE ] && [ "$STAT" = "" ]; then
                echo "gluu-server-$GLUU_VERSION is not running"
                exit 0
        elif [ -f $PIDFILE ] && [ ${#STAT[@]} = "6" ]; then
        	echo "Shutting down Gluu Server..."
        else
        	echo -e "ERROR: Can't stop gluu server.\nHINT: Please manually remove $PIDFILE and unmount chroot container by running\nrm -f $PIDFILE\ndf -aP | grep gluu-server-$GLUU_VERSION | awk '{print \$6}' | xargs -I {} umount -l {}"
        	exit 2
        fi

        if [ -x /opt/gluu-server-$GLUU_VERSION/etc/init.d/$APACHE ] && [ "`ps aux | grep $APACHE | grep -v grep`"  != "" ]; then
             	echo "Stopping Apache..."
            	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c "service $APACHE stop" > /dev/null 2>&1
                if [ "`ps aux | grep $APACHE | grep -v grep`"  != "" ]; then
                   echo "Failed"
                else
                   echo "OK"
                fi
        fi

        stopGenericService passport "Passport"
        stopGenericService oxauth-rp "oxAuth RP"
        stopGenericService asimba "Asimba"
        stopGenericService cas "CAS"
        stopGenericService idp "IDP"
        stopGenericService identity "oxTrust"
        stopGenericService oxauth "oxAuth"
        stopGenericService oxd "oxd-server"
        stopGenericService rsyslog "RSyslog"
        stopGenericService memcached "Memcached"

        if [ -x /opt/gluu-server-$GLUU_VERSION/etc/init.d/opendj ] && [ "`ps aux | grep opendj | grep -v grep`"  != "" ]; then
             	echo "Stopping OpendDJ..."
            	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c 'service opendj stop' > /dev/null 2>&1
                sleep 5
                if [ "`ps aux | grep opendj | grep -v grep`"  != "" ]; then
                   echo "Failed"
                else
                   echo "OK"
                fi
        fi

        if [ -x /opt/gluu-server-$GLUU_VERSION/etc/init.d/solserver ] && [ "`ps aux | grep slapd | grep -v grep`"  != "" ]; then
             	echo "Stopping OpenLDAP..."
            	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c 'service solserver stop' > /dev/null 2>&1
                sleep 5
                if [ "`ps aux | grep slapd | grep -v grep`"  != "" ]; then
                   echo "Failed"
                else
                   echo "OK"
                fi
        fi

        if ! [[ $DETECTED_OS == "Ubuntu 14.04" || $DETECTED_OS == "Ubuntu 16.04" || $DETECTED_OS == "Debian GNU/Linux 8" ]]; then
		/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c '/etc/rc.d/rc 7' > /dev/null 2>&1
        	sleep 5
        	/usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION su - root -c '/etc/init.d/denyhosts stop' &> /dev/null
		sleep 5
	fi

	/bin/umount -l /opt/gluu-server-$GLUU_VERSION/proc
	/bin/umount -l /opt/gluu-server-$GLUU_VERSION/sys/class/net/lo
	/bin/umount -l /opt/gluu-server-$GLUU_VERSION/lib/modules
	/bin/umount -l /opt/gluu-server-$GLUU_VERSION/dev/pts
	/bin/umount -l /opt/gluu-server-$GLUU_VERSION/dev

	rm -f $LOCK_PATH/gluu-server-$GLUU_VERSION $PIDFILE
	RETVAL=$?
	[ $RETVAL -eq 0 ] && rm -f $LOCK_PATH/gluu-server-$GLUU_VERSION
        echo
        return $RETVAL
}


status() {
        if [ -f $PIDFILE ] && [ ${#STAT[@]} = "6" ]; then
                PID=`cat $PIDFILE`
                echo gluu-server-$GLUU_VERSION is running: $PID
                exit 0
        elif [ ! -f $PIDFILE ] && [ ${#STAT[@]} = "0" ]; then
                echo "gluu-server-$GLUU_VERSION is not running"
                exit 1
        else
		echo -e "ERROR: gluu server was not run properly.\nHINT: Please manually remove $PIDFILE and unmount chroot container by running\nrm -f $PIDFILE\ndf -aP | grep gluu-server-$GLUU_VERSION | awk '{print \$6}' | xargs -I {} umount -l {}"
                exit 2
       fi

}

login() {
	if [ -f $PIDFILE ] && [ ${#STAT[@]} = "6" ]; then
                echo gluu-server-$GLUU_VERSION is running...
                echo logging in...
                /usr/sbin/chroot /opt/gluu-server-$GLUU_VERSION/ su -
        else
                echo "gluu-server-$GLUU_VERSION is not running"
                echo "please start it by running: /etc/init.d/gluu-server-$GLUU_VERSION start"
       fi

}

ready() {
        if [ -f $PIDFILE ] && [ ${#STAT[@]} = "6" ]; then
        	PID=`cat $PIDFILE`
                return 1
        elif [ -f $PIDFILE ] || [ "$STAT" != "" ]; then
            	return 1
        elif [ "$PORTS" != "" ]; then
            	return 1
	fi
        return 0
}

wait_stop() {
    	end=$((SECONDS+30))

    	while [ $SECONDS -lt $end ]; do
        	ready
        	STAT=$?
        	if [ $STAT = 0 ]; then
            		return 0
        	fi
        	sleep 5
    	done

    return 1
}


case "$1" in
      start)
         start
         ;;
    	install)
          rm -f /var/run/gluu-server-3.0.2.pid ; df -aP | grep gluu-server-3.0.2 | awk '{print $6}' | xargs -I {} umount -l {}
        	start
          /usr/sbin/chroot /opt/gluu-server-3.0.2/ /bin/bash -c "su - -c 'cd /install/community-edition-setup/; ./setup.py -n -f setup.properties'"
          while :; do
           sleep 300
          done
        ;;
    	stop)
        	stop
        ;;
    	status)
        	status
        ;;
    	restart)
        	stop
		wait_stop
        	start
        ;;
    login)
		login
	;;
    ready)
	;;
    *)

        echo "Usage:  {start|stop|status|restart|login|ready}"
        exit 1
        ;;
esac
exit $?
