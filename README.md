## 2ip platform installation

### Manual

Install with systemd:

```
apt-get update
apt-get install systemd
```

```
curl -O https://raw.githubusercontent.com/bis-gmbh/2ip-speed/master/systemd-install.sh  
chmod +x systemd-install.sh  
sudo ./systemd-install.sh  
```

Or install in rc.d:

```
curl -L "https://github.com/bis-gmbh/2ip-speed/releases/download/v4/2ip.speed.linux.x86_64.tar.gz" | tar zx
./speedtest --email=notification@example.com --port=8002
```

### Ansible (Linux only)

1) Clone repositories

```git clone https://github.com/bis-gmbh/2ip-speed.git```  

2) Change playbooks/hosts variables:
    - ansible_ssh_host

3) Install binaries and systemd:

```ansible-playbook -i playbooks/hosts playbooks/main.yml```
