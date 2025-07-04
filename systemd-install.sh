#!/bin/sh

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

INSTALL_PATH=/usr/local/bin
PORT=8002

MACHINE_TYPE=`uname -m`
OS=`uname | tr '[A-Z]' '[a-z]'`

USER_ID=$1

post_install() {
    SYSTEMD_CONFIG="[Unit]
Description=2ip speed
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_PATH/speedtest --id=$USER_ID --port=$PORT
ExecReload=/bin/kill -HUP \$MAINPID
User=nobody
AmbientCapabilities=CAP_NET_RAW
Restart=always
RestartSec=3
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
"
    [ -w /etc/systemd/system/ ] && \
        echo "$SYSTEMD_CONFIG" > "/etc/systemd/system/2ip-speed.service" || \
        sh -c "echo '$SYSTEMD_CONFIG' > /etc/systemd/system/2ip-speed.service"

    systemctl daemon-reload
    systemctl enable 2ip-speed.service
    systemctl start 2ip-speed.service
    systemctl status 2ip-speed.service

    echo "----------------------------------"
    echo " Fin "
    echo "----------------------------------"
}

get_bin() {
    echo "----------------------------------"
    echo " 2ip server binary downloading "
    echo "----------------------------------"

    curl -L "https://github.com/bis-gmbh/2ip-speed/releases/download/v4/2ip.speed.$OS.$MACHINE_TYPE.tar.gz" | tar zx

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
    echo "3) Linux arm_64"

    read -r -p "Select platform [1-5]: " NUMBER;
    case $NUMBER in
        1) OS='linux';
           MACHINE_TYPE='x86_64';;
        2) OS='linux';
           MACHINE_TYPE='x86_32';;
        3) OS='linux';
           MACHINE_TYPE='arm_64';;
        *) echo "FATAL: Please try to enter digit.";
           exit ;;
    esac
    install
}

pre_install() {
    if [ -z "$USER_ID" ]; then
        read -r -p "Please, enter ID: " USER_ID;
        if [ -z $USER_ID ]; then
            echo "ID not found"
            exit 1
        fi
    fi

    if [ "$(id -u)" != "0" ]; then
       echo "This script must be run as root" 1>&2
       exit 1
    fi

    read -r -p "Binary installation path [default: $INSTALL_PATH]: " PROMPT_PATH;
    if [ ! -z $PROMPT_PATH ]; then
        INSTALL_PATH=$PROMPT_PATH
    fi

    read -r -p "2ip speed server port [default: 8002]: " PORT_NEW;
    if [ ! -z $PORT_NEW ]; then
        PORT=$PORT_NEW
    fi

    if [ $OS = "linux" ]; then
        if [ $MACHINE_TYPE = "x86_32" ] || [ $MACHINE_TYPE = "x86_64" ] || [ $MACHINE_TYPE = "arm_64" ]; then
            install
        else
            select_os
        fi
    else
        select_os
    fi
}

pre_install
