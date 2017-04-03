## 2ip ansible platform installation on new server

1) Change playbooks/hosts variables:
    - ansible_ssh_host
    - node_host

2) Make letsencrypt certificates, crontab and put in /etc/2ip:

```ansible-playbook -i playbooks/hosts playbooks/install-certificate.yml```


3) Install binaries in /usr/bin/ and run systemd service:

```ansible-playbook -i playbooks/hosts playbooks/install-platform.yml```