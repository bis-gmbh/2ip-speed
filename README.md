## 2ip platform installation

### Ansible 

1) Clone repositories

```git clone https://github.com/bis-gmbh/2ip-speed-server.git```  
```cd 2ip-speed-server && git submodule update --init```
``````

2) Change playbooks/hosts variables:
    - ansible_ssh_host
    - node_host

3) Make letsencrypt certificates and crontab updates:

```ansible-playbook -i playbooks/hosts playbooks/1-get-letsencrypt.yml```

4) Make /etc/2ip and link /etc/letcencrypt/live/host certificates

```ansible-playbook -i playbooks/hosts playbooks/2-link-letsencrypt.yml```

5) Install binaries in /usr/bin/ and run systemd service:

```ansible-playbook -i playbooks/hosts playbooks/3-install.yml```
