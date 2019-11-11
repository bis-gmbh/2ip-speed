#!/bin/sh

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

INSTALL_PATH=/usr/local/bin
PORT=8001
CURRENT_HOSTNAME=`hostname -f`

MACHINE_TYPE=`uname -m`
OS=`uname | tr '[A-Z]' '[a-z]'`
USE_SYSTEMD=`grep -m1 -c systemd /proc/1/comm`

post_install() {
    case $(uname) in
    Linux)
        if [ $USE_SYSTEMD -eq 1 ]; then
            SYSTEMD_CONFIG="[Unit]
Description=2ip-speed
After=network.target 2ip-speed.socket
Requires=2ip-speed.socket

[Service]
NonBlocking=true
ExecStart=/usr/local/bin/speedtest --systemd=true --log=false --domain=$CURRENT_HOSTNAME --port=$PORT
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
"
            SOCKET_CONFIG="[Unit]
Description=2ip socket
PartOf=2ip-speed.service

[Socket]
ListenStream=80
NoDelay=true

[Install]
WantedBy=sockets.target
"
            INSTALL_SYSTEMD="N"
            read -r -p "Install systemd service? [y/N] " INSTALL_SYSTEMD;

            if [ $INSTALL_SYSTEMD = "y" ] || [ $INSTALL_SYSTEMD = "Y" ]; then
                [ -w /etc/systemd/system/ ] && \
                    echo "$SYSTEMD_CONFIG" > "/etc/systemd/system/2ip-speed.service" || \
                    sh -c "echo '$SYSTEMD_CONFIG' > /etc/systemd/system/2ip-speed.service"

                [ -w /etc/systemd/system/ ] && \
                    echo "$SOCKET_CONFIG" > "/etc/systemd/system/2ip-speed.socket" || \
                    sh -c "echo '$SOCKET_CONFIG' > /etc/systemd/system/2ip-speed.socket"

                systemctl daemon-reload
                systemctl start 2ip-speed.service
                systemctl status 2ip-speed.service
            fi
        else
            echo "----------------------------------------------------------------------------------------------------"
            echo " 2.1. Run command: sudo $INSTALL_PATH/speedtest --domain=$CURRENT_HOSTNAME --port=$PORT --log=false "
            echo "----------------------------------------------------------------------------------------------------"
        fi

        echo "----------------------------------------------"
        echo " 3. Go to isp control panel for add platform: "
        echo "----------------------------------------------"
        echo " wss://$CURRENT_HOSTNAME:$PORT/ws "
        echo " "

        return;
        ;;
    *)
    esac
}

get_bin() {
    echo "----------------------------------"
    echo " 2. 2ip server binary downloading "
    echo "----------------------------------"

    curl -L "https://github.com/bis-gmbh/2ip-speed/releases/download/v2.1/2ip.speed.$OS.$MACHINE_TYPE.tar.gz" | tar zx

    mkdir -p "$INSTALL_PATH"
    mv speedtest "$INSTALL_PATH"

    post_install
}

install() {
    get_bin
}

select_os() {
    echo "Please select server operation system [default: linux x86_64]:"
    echo "1) Linux x86_64"
    echo "2) Linux x86_32"
    echo "3) FreeBSD x86_64"
    echo "4) FreeBSD x86_32"
    echo "5) Darwin (macOS) x86_64)"

    read -r -p "Select platform [1-5]: " NUMBER;
    case $NUMBER in
        1) OS='linux';
           MACHINE_TYPE='x86_64';;
        2) OS='linux';
           MACHINE_TYPE='x86_32';;
        3) OS='freebsd';
           MACHINE_TYPE='x86_64';;
        4) OS='freebsd';
           MACHINE_TYPE='x86_32';;
        5) OS='darwin';
           MACHINE_TYPE='x86_64';;
        *) echo "FATAL: Please try to enter digit.";
           exit ;;
    esac
    install
}

pre_install() {
    if [ "$(id -u)" != "0" ]; then
       echo "This script must be run as root" 1>&2
       exit 1
    fi

    if [ "$(netstat -an | grep " 80 " | grep LISTEN | wc -l)" -gt "0" ]; then
       echo "Let's Encrypt verification port 80 not available" 1>&2
       exit 1
    fi

    read -r -p "Binary installation path [default: $INSTALL_PATH]: " PROMPT_PATH;
    if [ ! -z $PROMPT_PATH ]; then
        INSTALL_PATH=$PROMPT_PATH
    fi

    read -r -p "Domain [default: $CURRENT_HOSTNAME]: " NEW_HOST;
    if [ ! -z $NEW_HOST ]; then
        CURRENT_HOSTNAME=$NEW_HOST
    fi

    read -r -p "2ip speed server port [default: 8001]: " PORT_NEW;
    if [ ! -z $PORT_NEW ]; then
        PORT=$PORT_NEW
    fi

    if [ $OS = "linux" ]; then
        if [ $MACHINE_TYPE = "x86_32" ] || [ $MACHINE_TYPE = "x86_64" ]; then
            install
        else
            select_os
        fi
    else
        select_os
    fi
}

pre_install
