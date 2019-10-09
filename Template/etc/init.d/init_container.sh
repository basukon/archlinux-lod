#! /bin/sh

# Export PATH 
export PATH=/usr/bin:/usr/sbin

export VIRTUALIZATION=1

dmesg > /var/log/dmesg.log
chmod 0644 /var/log/dmesg.log

mkdir -p -m0755 /run/lvm /run/user /run/lock /run/log

install -m0664 -o root -g utmp /dev/null /run/utmp

cp /var/lib/random-seed /dev/urandom >/dev/null
( umask 077; bytes=$(cat /proc/sys/kernel/random/poolsize) || bytes=512; dd if=/dev/urandom of=/var/lib/random-seed count=1 bs=$bytes >/dev/null 2>&1 )

if [ -x /sbin/sysctl -o -x /bin/sysctl ]; then 
    msg "Loading sysctl(8) settings..." 
    for i in /run/sysctl.d/*.conf \
        /etc/sysctl.d/*.conf \
        /usr/local/lib/sysctl.d/*.conf \
        /usr/lib/sysctl.d/*.conf \
        /etc/sysctl.conf; do 

        if [ -e "$i" ]; then
            printf '* Applying %s ...\n' "$i" 
            sysctl -p "$i" 
        fi 
    done
fi

if [ ! -e /etc/machine-id ]; then
    systemd-machine-id-setup
fi
if [ ! -e /etc/locale.conf ]; then
    systemd-firstboot --locale=en_US.UTF-8
fi

if [ ! -e /var/log/wtmp ]; then
    install -m0664 -o root -g utmp /dev/null /var/log/wtmp
fi 
if [ ! -e /var/log/btmp ]; then
    install -m0600 -o root -g utmp /dev/null /var/log/btmp 
fi 

install -dm1777 /tmp/.X11-unix /tmp/.ICE-unix

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


TARGET="$1"
LOGIN_USER="dextop"


case "$TARGET" in
    SHELL)
        sudo -i -u $LOGIN_USER /bin/bash --login #NOTE: synchronous call
        ;;
    RSHELL)
        sudo -i -u root /bin/bash --login #NOTE: synchronous call
        ;;
    GUI)
	# Start services 
	mkdir -p /run/uuidd
        mkdir -p /run/dbus
        /usr/bin/uuidd -F -P > /var/log/uuidd.log 2>&1 &
        /usr/lib/systemd/systemd-udevd > /var/log/udev.log 2>&1 & 
        #/usr/bin/dbus-daemon --system --nofork --nopidfile --syslog-only > /var/log/dbus.log 2>&1 &
        #/usr/lib/polkit-1/polkitd --no-debug > /var/log/polkitd.log 2>&1 &

        # Start vnc service (check ~/.vnc/xstartup to set your environment) 
        lxd_set_timezone $4
        /etc/init.d/vnc.sh $2 $3 $LOGIN_USER
        ;;
    APP)
        lxd_set_timezone $4 
        /etc/init.d/vnc.sh $2 $3 #NOTE: synchronous call
        ;;
    TERM)
	sudo -i -u $LOGIN_USER setsid /bin/bash --login >/devro/tty1 2>&1 </devro/tty1
	#setsid /bin/bash --login >/devro/tty1 2>&1 </devro/tty1
        ;;
    *) ee "unexpected argument: $TARGET" usage exit 1
        ;;
esac
