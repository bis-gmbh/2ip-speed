#!/bin/sh

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

INSTALL_PATH=/usr/local/bin
PORT=8001

MACHINE_TYPE=`uname -m`
OS=`uname | tr '[A-Z]' '[a-z]'`
USE_SYSTEMD=`grep -m1 -c systemd /proc/1/comm`

get_certificates() {
    while [ -z "$DOMAIN" ]; do
        read -r -p "Enter domain name for speed platform [example.test]: " DOMAIN;
    done ;

    echo "-------------------------------------------"
    echo " 1. Letsencrypt certificate installation "
    echo "-------------------------------------------"

    curl -o $INSTALL_PATH/certbot-auto "https://dl.eff.org/certbot-auto"
    chmod a+x $INSTALL_PATH/certbot-auto

    $INSTALL_PATH/certbot-auto certonly --non-interactive --standalone --email dev@2ip.ru --agree-tos -d $DOMAIN

    echo "-------------------------------------------"
    echo " 1.1. Crontab autorenew "
    echo "-------------------------------------------"

    CMD="$INSTALL_PATH/certbot-auto renew --renew-hook \"systemctl restart 2ip-speed\" > /dev/null 2>&1"
    JOB="0 12 * * * $CMD"

    if [ -d "/etc/letsencrypt/live/" ]; then
        ( crontab -l | grep -v -F "$CMD" ; echo "$JOB" ) | crontab -

        chmod -R 755 /etc/letsencrypt/live/
        chmod -R 755 /etc/letsencrypt/archive/
    else
        echo "Let's Encrypt installation failed"
        exit 1
    fi
}

post_install() {
    case $(uname) in
    Linux)
        if [ $USE_SYSTEMD -eq 1 ]; then
            SYSTEMD_CONFIG="[Unit]
Description=2ip speed
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_PATH/speedtest --certdir=/etc/letsencrypt/live/$DOMAIN --port=$PORT
ExecReload=/bin/kill -HUP \$MAINPID
User=nobody
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
"
            INSTALL_SYSTEMD="N"
            read -r -p "Install systemd service? [y/N] " INSTALL_SYSTEMD;

            if [ $INSTALL_SYSTEMD = "y" ] || [ $INSTALL_SYSTEMD = "Y" ]; then
                [ -w /etc/systemd/system/ ] && \
                    echo "$SYSTEMD_CONFIG" > "/etc/systemd/system/2ip-speed.service" || \
                    sh -c "echo '$SYSTEMD_CONFIG' > /etc/systemd/system/2ip-speed.service"

                systemctl daemon-reload
                systemctl start 2ip-speed.service
                systemctl status 2ip-speed.service
            fi
        else
            echo "------------------------------------------------------------------------------------------------"
            echo " 2.1. Run command: $INSTALL_PATH/speedtest --certdir=/etc/letsencrypt/live/$DOMAIN --port=$PORT "
            echo "------------------------------------------------------------------------------------------------"
        fi

        echo "----------------------------------------------"
        echo " 3. Go to isp control panel for add platform: "
        echo "----------------------------------------------"
        echo " wss://$DOMAIN:$PORT/ws "
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

    curl -L "https://github.com/bis-gmbh/2ip-speed/releases/download/latest/2ip.speed.$OS.$MACHINE_TYPE.tar.gz" | tar zx

    mkdir -p "$INSTALL_PATH"
    mv speedtest "$INSTALL_PATH"

    post_install
}

install() {
    get_certificates
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

    if [ "$(netstat -an | grep 443 | grep LISTEN | wc -l)" -gt "0" ]; then
       echo "Let's Encrypt verification port 443 not available" 1>&2
       exit 1
    fi

    read -r -p "Binary installation path [default: $INSTALL_PATH]: " PROMPT_PATH;
    if [ ! -z $PROMPT_PATH ]; then
        INSTALL_PATH=$PROMPT_PATH
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