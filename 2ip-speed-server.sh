#!/usr/bin/env sh

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

INSTALL_PATH=/usr/local/bin
MACHINE_TYPE=`uname -m`
OS=`uname | tr '[A-Z]' '[a-z]'`

get_certificates() {
    while [ -z "$DOMAIN" ]; do
        read -r -p "Enter domain name for speed platform [example.test]: " DOMAIN;
    done ;

    echo "-------------------------------------------"
    echo " 1. Letsencrypt certbot downloading "
    echo "-------------------------------------------"

    curl -O "https://dl.eff.org/certbot-auto"
    chmod a+x certbot-auto

    echo "-------------------------------------------"
    echo " 1.1. Letsencrypt certificate installation "
    echo "-------------------------------------------"
    ./certbot-auto certonly --non-interactive --standalone --email dev@2ip.ru --agree-tos -d $DOMAIN

    sudo chmod -R 755 /etc/letsencrypt/live/
    sudo chmod -R 755 /etc/letsencrypt/archive/
}

post_install() {
    case $(uname) in
    Linux)
        if [ -d "/etc/systemd/" ]; then
            SYSTEMD_CONFIG="[Unit]
Description=2ip speed
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_PATH/speedtest --certdir=/etc/letsencrypt/live/$DOMAIN
ExecReload=/bin/kill -HUP \$MAINPID
User=nobody
Group=nogroup
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
                    sudo sh -c "echo '$SYSTEMD_CONFIG' > /etc/systemd/system/2ip-speed.service"

                sudo systemctl daemon-reload
                sudo systemctl start 2ip-speed.service
                sudo systemctl status 2ip-speed.service
            fi

            return;
        fi
        ;;
    *)
    esac
}

get_bin() {
    echo "-------------------------------------------"
    echo " 2. 2ip server binary downloading "
    echo "-------------------------------------------"

    curl -L "https://github.com/bis-gmbh/2ip-speed/releases/download/latest/2ip.speed.$OS.$MACHINE_TYPE.tar.gz" | tar zx

    if [ -w "$INSTALL_PATH" ]; then
        mkdir -p $INSTALL_PATH
        mv speedtest "$INSTALL_PATH"
    else
        sudo mkdir -p "$INSTALL_PATH"
        sudo mv speedtest "$INSTALL_PATH"
    fi

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
    read -r -p "Binary installation path [default: $INSTALL_PATH]: " PROMPT_PATH;
    if [ ! -z $PROMPT_PATH ]; then
        INSTALL_PATH=$PROMPT_PATH
    fi

    if [ $OS = "linux" ] || [ $OS = "freebsd" ] || [ $OS = "darwin" ]; then
        if [ $MACHINE_TYPE = "x86_32" ] || [ $MACHINE_TYPE = "x86_64" ]; then
            install
        else
            select_os
        fi
    else
        select_os
    fi
}

usage() {
    echo " 2ip platform installation script"
    echo " "
    echo " Commands: install, usage"
    echo "     install - download and install SSL certificates and 2ip server"
    echo " "
    echo " -i|install"
    echo " -h|help"
    echo ""
}

while [ "$1" != "" ]; do
    case $1 in
        install | -i )          pre_install
                                exit
                                ;;
        help | -h | --help )	usage
                                exit
                                ;;
        * )                     usage
                                exit
    esac
done