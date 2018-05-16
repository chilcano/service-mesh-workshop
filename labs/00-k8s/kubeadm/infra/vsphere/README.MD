
```bash
$ ssh-keygen -R hostname

$ ansible all -i inventory -m "ping" -k
$ ansible all -i inventory -a "cat /etc/hostname" -k
$ ansible all -i inventory -a "cat /etc/hosts" -k
$ ansible all -i inventory -a "ping -c 2 pi17.intix.info" -k
$ ansible all -i inventory -a "ping -c 3 holisticsecurity.io" -k
$ ansible all -i inventory -a "df -h" -k
$ ansible all -i inventory -a "ifconfig ens160" -k
$ ansible all -i inventory -a "shutdown -r now" -k
$ ansible masters -m shell -a "sudo apt-get update" -k



export http_proxy="http://10.0.11.1:3128"
export https_proxy="http://10.0.11.1:3128"
export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"


list of ubuntu repositories:

$ egrep -v '^#|^ *$' /etc/apt/sources.list /etc/apt/sources.list.d/*

```
