#! /bin/sh
# vim: expandtab:tabstop=4:softtabstop=4:shiftwidth=4:autoindent:cindent

# This script is written in a way that it can work properly regardless
# of current working directory.

LOGTAG="init_container"


chmod 01777 /run


#============================================================================
# Parse Arguments And Set Default Values
#============================================================================
TARGET="$1"

test ".$TARGET" = . && TARGET=GUI


#============================================================================
# Helper Fucitons
#============================================================================

ei () { printf "[INF] $LOGTAG: $1\n";:;}  #ei=emit inf msg
ew () { printf "[WRN] $LOGTAG: $1\n";:;}  #ew=emit wrn msg
ee () { printf "[ERR] $LOGTAG: $1\n";:;}  #ee=emit err msg


usage ()
{
    cat <<EOF

  USAGE:
      $0 [<target>]

  DESCRPIPTION:
      This script initializes the execution environment of a 'container'.

  ARGUMENTS:
      <target> - target work mode, the value can be GUI, SHELL or RSHELL.
                 GUI value is considered by default.

  EXAMPLES:
      $0 GUI  	#init container and run X Server (using VNC Server)
      $0 SHELL	#init container and run /bin/bash as 'dextop' user

EOF
}


ifmounted ()
{
    local FSTYPE="$1"
    local MNTPATH="$2"
    local S="$(mount -t "$FSTYPE" | grep "on $MNTPATH")"
    #if string S is not empty then consider as 'yes, already mounted'
    test -n "$S" && return 0 || return 1
}

mount_if_not_mounted ()
{
    local FSTYPE="$1"
    local MNTPATH="$2"
    ifmounted "$FSTYPE" "$MNTPATH" \
        && ei "ok, already mounted: $MNTPATH" \
        || mount "$MNTPATH"
}

#============================================================================
# Basic Sanity Check
#============================================================================

# The login, agetty, and init programs (and others) use a number of log files
# to record information such as who was logged into the system and when. 
# However, these programs will not write to the log files if they do not
# already exist. Initialize the log files and give them proper permissions:
touch /var/run/utmp /var/log/btmp /var/log/lastlog /var/log/wtmp
chgrp -v utmp /var/run/utmp /var/log/lastlog
chmod -v 664 /var/run/utmp /var/log/lastlog

test -f /etc/profile || {
    ee "pls, execute this script inside the container"
    exit 1
}

. /etc/profile

#============================================================================
# Setup Mount Table
#============================================================================
lxd_setup_mount_table ()
{
mount -t proc 2>/dev/null || mount -t proc /proc

mount_if_not_mounted  sysfs      /sys
mount_if_not_mounted  devtmpfs   /dev

mkdir -p /dev/pts
mount_if_not_mounted  devpts     /dev/pts

mkdir -p /dev/shm
mount_if_not_mounted  tmpfs      /dev/shm

mount_if_not_mounted  tmpfs      /run

mkdir -p /run/lock
mkdir -p /run/shm
mkdir -p /run/user
#mkdir -p /run/rpc_pipefs

mount_if_not_mounted  tmpfs      /run/lock
mount_if_not_mounted  tmpfs      /run/shm
mount_if_not_mounted  tmpfs      /run/user
#mount_if_not_mounted rpc_pipefs /run/rpc_pipefs

mkdir  -p /sys/fs/cgroup

#mkdir -p /sys/fs/fuse/connections
#mkdir -p /sys/kernel/debug
#mkdir -p /sys/kernel/security
#mkdir -p /sys/fs/pstore

mount_if_not_mounted  tmpfs      /sys/fs/cgroup
mkdir  -p /sys/fs/cgroup/cpu
mkdir  -p /sys/fs/cgroup/cpuset
mkdir  -p /sys/fs/cgroup/cpuacct
#mkdir  -p /sys/fs/cgroup/blkio
mkdir  -p /sys/fs/cgroup/memory
mkdir  -p /sys/fs/cgroup/devices
mkdir  -p /sys/fs/cgroup/net_cls
mkdir  -p /sys/fs/cgroup/net_prio
mkdir  -p /sys/fs/cgroup/perf_event
mkdir  -p /sys/fs/cgroup/freezer
mkdir  -p /sys/fs/cgroup/pids

mount_if_not_mounted cgroup    /sys/fs/cgroup/cpu
mount_if_not_mounted cgroup    /sys/fs/cgroup/cpuset
mount_if_not_mounted cgroup    /sys/fs/cgroup/cpuacct
#mount_if_not_mounted cgroup    /sys/fs/cgroup/blkio
mount_if_not_mounted cgroup    /sys/fs/cgroup/memory
mount_if_not_mounted cgroup    /sys/fs/cgroup/devices
mount_if_not_mounted cgroup    /sys/fs/cgroup/net_cls
mount_if_not_mounted cgroup    /sys/fs/cgroup/net_prio
mount_if_not_mounted cgroup    /sys/fs/cgroup/perf_event
mount_if_not_mounted cgroup    /sys/fs/cgroup/freezer
mount_if_not_mounted cgroup    /sys/fs/cgroup/pids
#mount_if_not_mounted fusectl    /sys/fs/fuse/connections
#mount_if_not_mounted debugfs    /sys/kernel/debug
#mount_if_not_mounted securityfs /sys/kernel/security
#mount_if_not_mounted pstore     /sys/fs/pstore

mkdir -p /sys/fs/cgroup/systemd
mount_if_not_mounted  cgroup     /sys/fs/cgroup/systemd
}

#============================================================================
# Run Services
#============================================================================

lxd_run_services ()
{
echo "place holder"
#service apport start
#service lvm2-lvmetad start
#service lvm2-lvmpolld start
#service rsyslog start
#service unattended-upgrades start
#service uuidd start
#service anacron start
#service rsync start
#service cron start
#service dbus start
#service irqbalance start
#service mdadm start
#service rsync start
}

#============================================================================
# Timezone setting
#============================================================================
lxd_set_timezone ()
{
    ei "timezone = $1"
    test -e /usr/share/zoneinfo/$1 || {
        ew "Failed to set the time zone for the Guest Linux"
        return
    }

    # /etc/timezone setting
    sed -e '1d' /etc/timezone > /etc/timezone.tmp && mv -f /etc/timezone.tmp /etc/timezone
    # tail -n +2 /etc/timezone > /etc/timezone.tmp && mv /etc/timezone.tmp /etc/timezone
    printf $1"\n" >> /etc/timezone
    
    # /etc/localtime setting
    rm -rf /etc/localtime
    ln -sf /usr/share/zoneinfo/$1 /etc/localtime
}

#============================================================================
# Enter The Target Work Mode: GUI or SHELL
#============================================================================

case "$TARGET" in

    SHELL)
        #lxd_setup_mount_table
        sudo -i -u dextop /bin/bash --login           #NOTE: synchronous call
        ;;

    RSHELL)
        #lxd_setup_mount_table
        sudo -i -u root /bin/bash --login             #NOTE: synchronous call
        ;;

    GUI)
        #lxd_setup_mount_table
        lxd_run_services
        lxd_set_timezone $4
        /usr/bin/lod_daemon &
        /etc/init.d/vnc.sh $2 $3                     #NOTE: synchronous call
        #ulimit -l 16384   #needed for unity-greeter on CROWN-QC, LOG2ALL-265
        #service lightdm start
        ;;

    APP)
        #lxd_setup_mount_table
        lxd_run_services
        lxd_set_timezone $4
        /etc/init.d/vnc.sh $2 $3                           #NOTE: synchronous call
        ;;

    TERM)
        #lxd_setup_mount_table
        lxd_run_services
        lxd_set_timezone $4
        sudo    -u dextop screen -dmS bgSessionToKeepDevPts0Alive
        sudo -i -u dextop setsid /bin/bash --login >/devro/tty1 2>&1 < /devro/tty1
        ;;

    *)
        ee "unexpected argument: $TARGET"
        usage
        exit 1
        ;;
esac


ei "execution of target '$TARGET' completed"

