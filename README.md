## 2ip platform installation

### Manual

Install:

```
curl -O "https://raw.githubusercontent.com/bis-gmbh/2ip-speed/master/2ip-speed-server.sh"
chmod +x 2ip-speed-server.sh
./2ip-speed-server.sh
```

Linux dependencies (optional):

```
apt-get update
apt-get install systemd
```

### Ansible (linux only)

1) Clone repositories

```git clone https://github.com/bis-gmbh/2ip-speed.git```  
```cd 2ip-speed && git submodule update --init```

2) Change playbooks/hosts variables:
    - ansible_ssh_host
    - node_host

3) Make letsencrypt certificates and crontab updates (skip if exist):

```ansible-playbook -i playbooks/hosts playbooks/main.yml```
