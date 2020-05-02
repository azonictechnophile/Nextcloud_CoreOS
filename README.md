# Install Nextcloud Stable with Nginx + Database (MariaDB/PostgreSQL/SQLite) + Encryption (Let's Encrypt Certificate/Self-signed) + Portainer, Office, and Adminer on Fedora Core OS.

This is for a relatively handfree install of Nextcloud with Nginx and other options on Fedora CoreOS only. This script is designed with the installation of Nextcloud on its own VM without other containers. 

It was design with security in mind. Currently, the only package with access to docker.sock is Portainer and Dockerproxy. Traefik uses the dockerproxy on a seperate network in order to access the docker.sock for more security. Portainer does not use Traefik for https access, it is directly thru port 9000. Firewalld is installed and can be made more secure with stricter rules.

Only ports open are 22, 80, 443, and 9000 (if portainer is installed) for TCP traffic only.

## Preparation

To keep Fedora CoreOS (FCOS) as minimal as possible, you will need run the install script on your FCOS server first, and then download the github repository on computer that has ansible installed. Ansible will then install Nextcloud remotely over SSH.

Run the following in your CoreOS installation. 

When installing Fedora Core OS, you will need to use an ignition file. The example I have here is for an install using the VMWare.ova and using vSphere for the installation. With the [FCOS](https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/31.20200407.3.0/x86_64/fedora-coreos-31.20200407.3.0-vmware.x86_64.ova) OVA you will need to provide the json file in a base64 format. The provide one will setup Fedora CoreOS with a username core, as well as setup the network as dhcp. The installation will require you insert your ssh pub key into the .ign file before you encode it. See the example screenshot. Simply go to base64encode.org upload your file and it will product a text file where you copy that into the output of the base64 convert into the "Inline Ignition config data"

Then type "bash64" into the "Ignition config data encoding"

![Example on vSphere](https://github.com/azonictechnophile/Nextcloud_CoreOS/blob/master/vmware%20example.png)

NOTE: The inventory file is set to use the username core and password core for ansible to ssh into the server.

Once completed you should be able to log into the server.

For editing network location, after installation is complete and you can log in. Go to:
```bash
/etc/NetworkManager/system-connections/eth0.nmconnection
```

On the FCOS install run the following:
```bash
curl -s https://raw.githubusercontent.com/azonictechnophile/Nextcloud_CoreOS/prepare_system.sh | /bin/bash
```

Clone this repo on your ansible installation server and change into the directory Nextcloud_CoreOS.

```bash
git clone https://github.com/azonictechnophile/Nextcloud_CoreOS

cd Nextcloud_CoreOS
```

Note that root must have also sudo right otherwise the script will complain. Some hoster use distros where root is not in the sudoers file. In this case you have to add `root ALL=(ALL) NOPASSWD:ALL` to /etc/sudoers.

## Non-VMWare vSphere Installs

If you install using the iso instead. You can use the .ign and following the instructions at https://docs.fedoraproject.org/en-US/fedora-coreos/bare-metal/ to install with user name "core" and password "core".


## Configuration

Now you can configure the whole thing by editing the file `inventory` and some other files. Be sure to put the nextcloud server ip address at the top of the inventory file.

### Preliminary variables

First of all you must define the server fqdn. If you want to get a Let's Encrypt certificate this must be a valid DNS record pointing to your server. Port 80+443 must be open to the internet. 

If you have a private server or if you use an AWS domain name like `ec2-52-3-229-194.compute-1.amazonaws.com`, you'll end up with a self-signed certificate. This is fine but annoying, because you have to accept this certificate manually in your browser. If you don't have a fqdn use the server IP address.

*Important:* You will only be able to access Nextcloud through this address. 
```ini
# The domain name for your Nextcloud instance. You'll get a Let's Encrypt certificate for this domain.
nextcloud_server_fqdn       = nextcloud.example.com
```

Let's Encrypt wants your email address. Enter it here:
```ini
# Your email address (for Let's Encrypt).
ssl_cert_email              = nextcloud@example.com
```

### Nextcloud variables

Define where you want to find your Nextcloud program, config, database and data files in the hosts filesystem.
```ini
# Choose a directory for your Nextcloud data.
nextcloud_base_dir          = /opt/nextcloud
```

Define your Nextcloud admin user.
```ini
# Choose a username and password for your Nextcloud admin user.
nextcloud_admin             = 'admin'
nextcloud_passwd            = ''              # If empty the playbook will generate a random password.
```

Now it's time to choose and configure your favorite database management system.
```ini
# You must choose one database management system.
# Choose between 'pgsql' (PostgreSQL, default), 'mysql' (MariaDB) and 'sqlite' (SQLite).
nextcloud_db_type           = 'mysql'

# Options for Mariadb and PostgreSQL.
nextcloud_db_host           = 'localhost'
nextcloud_db_name           = 'nextcloud'
nextcloud_db_user           = 'nextcloud'
nextcloud_db_passwd         = ''              # If empty the playbook will generate a random password (stored in {{ nextcloud_base_dir }}/secrets ).
nextcloud_db_prefix         = 'oc_'
```

### Optional variables

If you want to setup the Nextcloud mail system put your mail server config here.
```ini
# Setup the Nextcloud mail server.
nextcloud_configure_mail    = false
nextcloud_mail_from         =
nextcloud_mail_smtpmode     = smtp
nextcloud_mail_smtpauthtype = LOGIN
nextcloud_mail_domain       =
nextcloud_mail_smtpname     =
nextcloud_mail_smtpsecure   = tls
nextcloud_mail_smtpauth     = 1
nextcloud_mail_smtphost     =
nextcloud_mail_smtpport     = 587
nextcloud_mail_smtpname     =
nextcloud_mail_smtppwd      =
```

This playbook supports the integration with an online office suite. You can choose between [Collabora](https://www.collaboraoffice.com/) and [ONLYOFFICE](https://www.onlyoffice.com).
```ini
# Choose an online office suite to integrate with your Nextcloud. Your options are (without quotation marks): 'none', 'collabora' and 'onlyoffice'.
online_office               = none
# When using Collabora, you're able to install dictionaries alongside with it. Collabora's default is German (de).
# collabora_dictionaries    = 'en'            # Separate ISO 639-1 codes with a space.
```

You can install the TURN server, if needed for [Nextcloud Talk](https://nextcloud.com/talk/).
```ini
# Set to true to install TURN server for Nextcloud Talk.
talk_install                = false
```

If you want to, you can get access to your database with [Adminer](https://www.adminer.org/). Adminer is a web frontend for your database (like phpMyAdmin).
```ini
# Set to true to enable access to your database with Adminer at https://nextcloud_server_fqdn/adminer .
adminer_enabled             = false           # The password will be stored in {{ nextcloud_base_dir }}/secrets .
```

You can install [Portainer](https://www.portainer.io/), a webgui for Docker.
```ini
# Set to true to install Portainer webgui for Docker.
portainer_enabled           = false
portainer_passwd            = ''              # If empty the playbook will generate a random password.
```
## Installation

Run the Ansible playbook on your server with ansible install. Ensure that you have passlib, bcrypt, and selinux pip3 packages installed.
```bash
./nextdocker.yml
```

Your Nextcloud access credentials will be displayed at the end of the run.

```json
ok: [localhost] => {
    "msg": [
        "Your Nextcloud at https://cloud.example.com is ready.",
        "Login with user: admin and password: fTkLgvPYdmjfalP8XgMsEg7plnoPsTvp ",
        "Other secrets you'll find in the directory /opt/nextcloud/secrets "
    ]
}
....
ok: [localhost] => {
    "msg": [
        "Manage your container at https://nextcloud_server_ip:9000/ .",
        "Login with user: admin and password: CqDy4SqAXC5kEU0hHGQ5IucdBegwaVXa "
    ]
}

```

If you are in a hurry you can set the inventory variables on the cli. But remember if you run the playbook again without the -e options all default values will apply and your systems is likely to be broken.

```bash
./nextdocker.yml -e "nextcloud_server_fqdn=nextcloud.example.tld nextcloud_db_type=mysql"
```

## Expert setup

If you change anything in the below mentioned files the playbook might not work anymore. You need a basic understanding of Linux, Ansible, Jinja2 and yaml to do so.

If you want to do more fine tuning you may have a look at:

- `group_vars\all.yml` for settings of directories, docker image tags and the rclone setup for restic backups.
- `roles\docker_container\file` for php settings
- `roles\docker_container\file` for webserver, php, turnserver and traefik settings

and

- `roles\nextcloud_config\defaults\main.yml` for nextcloud settings

## Remove Nextcloud

If you want to get rid of the containers run the following command.
```bash
ansible-playbook nextdocker.yml -e state=absent
```

Also run the scripts/remove_all_docker_stuff.sh, but this will remove all containers on the host.
```bash
scripts/remove_all_docker_stuff.sh
```

Your data won't be deleted. You have to do this manually by executing the following.
```bash
rm -rf {{ nextcloud_base_dir }}
```
