## 2ip platform installation

At first get uniq ID: [https://2ip.io/isp-platforms/](https://2ip.io/isp-platforms/)

### Systemd

```
apt-get update
apt-get install systemd
```

```
curl -O https://raw.githubusercontent.com/bis-gmbh/2ip-speed/master/systemd-install.sh  
chmod +x systemd-install.sh  
sudo ./systemd-install.sh UNIQ_ID
```

### Manual

```
curl -L "https://github.com/bis-gmbh/2ip-speed/releases/download/v4/2ip.speed.linux.x86_64.tar.gz" | tar zx
./speedtest --id=UNIQ_ID
```

### Ansible

1. Clone repositories

```git clone https://github.com/bis-gmbh/2ip-speed.git```

2. Change playbooks/hosts variables:
   - ansible_ssh_host
   - uniq_id – Take [here](https://2ip.io/isp-platforms/)

3. Install binaries and systemd:

```ansible-playbook -i playbooks/hosts playbooks/main.yml```
