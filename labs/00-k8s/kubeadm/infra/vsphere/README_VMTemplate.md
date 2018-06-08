# Preparing VM as Template

Requisites:
- Ubuntu 16.04 Xenial

## 0. Useful commands

Remove `172.16.70.111` ssh key.
```bash
$ ssh-keygen -R 172.16.70.111
```

Ansible commands.
```bash
$ ansible all -i inventory -m "ping" -k
$ ansible all -i inventory -a "cat /etc/hostname" -k
$ ansible all -i inventory -a "cat /etc/hosts" -k
$ ansible all -i inventory -a "ping -c 2 pi17.intix.info" -k
$ ansible all -i inventory -a "ping -c 3 holisticsecurity.io" -k
$ ansible all -i inventory -a "df -h" -k
$ ansible all -i inventory -a "ifconfig ens160" -k
$ ansible all -i inventory -a "sudo shutdown -r now" -k -K
$ ansible masters -m shell -a "sudo reboot" -k -K
$ ansible masters -m shell -a "sudo apt-get update" -k -K

$ ansible masters -m "setup" -k
$ ansible masters -m "setup" -a "filter=ansible_ens160" -k

$ ansible all -m "setup" -a "filter=ansible_distribution" -k
...
Debian
$ ansible all -m "setup" -a "filter=ansible_distribution_release" -k
...
stretch
```

## 1. Preparing VM as Template

```bash
// env for wget, ...
export http_proxy="http://10.0.11.1:3128"
export https_proxy="http://10.0.11.1:3128"
export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

// env for apt
k8sadmin@ob1:~$ sudo nano /etc/apt/apt.conf.d/apt.conf

Acquire::http::proxy "http://10.0.11.1:3128/";
Acquire::https::proxy "http://10.0.11.1:3128/";

localpc $ wget https://packages.cloud.google.com/apt/doc/apt-key.gpg
localpc $ scp apt-key.gpg k8sadmin@ob1:/home/k8sadmin/.

k8sadmin@ob1:~$ apt-key list
k8sadmin@ob1:~$ sudo apt-key add apt-key.gpg
...
pub   2048R/A7317B0F 2015-04-03 [expired: 2018-04-02]
uid                  Google Cloud Packages Automatic Signing Key <gc-team@google.com>

// list of ubuntu repositories:
k8sadmin@ob1:~$ egrep -v '^#|^ *$' /etc/apt/sources.list /etc/apt/sources.list.d/*

// update your '/etc/hosts' file:
$ sudo nano /etc/hosts

172.16.70.10  ob1
```
