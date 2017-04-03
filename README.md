## 2ip ansible platform installation on new server

1) Clone repositories

```git clone https://github.com/bis-gmbh/2ip-speed-server.git```
```git submodule update --init```

2) Change playbooks/hosts variables:
    - ansible_ssh_host
    - node_host

3) Make letsencrypt certificates, crontab and put in /etc/2ip:

```ansible-playbook -i playbooks/hosts playbooks/install-certificate.yml```


4) Install binaries in /usr/bin/ and run systemd service:

```ansible-playbook -i playbooks/hosts playbooks/install-platform.yml```