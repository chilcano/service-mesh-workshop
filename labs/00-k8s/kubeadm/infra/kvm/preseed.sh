#!/bin/bash

cd "$(dirname $0)"

NODE=${1:?node nr}
HOST=${2:?hostname}
PASSWD=${3:?passwd}
KEYPUB=${4:?keypub}
DIR=/var/kvm/mosaico
mkdir -p $DIR/$HOST

cat <<XXX_END_OF_FILE_XXX >$DIR/$HOST/preseed.cfg
### Localization
# Preseeding only locale sets language, country and locale.
d-i debian-installer/locale string en_GB.UTF-8

# Keyboard selection.
# Disable automatic (interactive) keymap detection.
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/layoutcode string gb

### Network configuration
# netcfg will choose an interface that has link if possible. This makes it
# skip displaying a list if there is more than one interface.
d-i netcfg/choose_interface select auto

# Just in case our DHCP server is busy.
d-i netcfg/dhcp_timeout string 60

# Any hostname and domain names assigned from dhcp take precedence over
# values set here. However, setting the values still prevents the questions
# from being shown, even if values come from dhcp.
d-i netcfg/get_hostname string $HOST
d-i netcfg/get_domain string kube

# Disable that annoying WEP key dialog.
d-i netcfg/wireless_wep string

# Added by @analytically: always install the server kernel
d-i	base-installer/kernel/override-image string linux-server

### Mirror settings
# Alternatively: by default, the installer uses CC.archive.ubuntu.com where
# CC is the ISO-3166-2 code for the selected country. You can preseed this
# so that it does so without asking.
d-i mirror/country string gb
d-i mirror/http/mirror select gb.archive.ubuntu.com
d-i mirror/http/proxy string gb.archive.ubuntu.com

### Clock and time zone setup
# Controls whether or not the hardware clock is set to UTC.
d-i clock-setup/utc boolean true

# You may set this to any valid setting for $TZ; see the contents of
# /usr/share/zoneinfo/ for valid values.
d-i time/zone string Etc/UTC

# Controls whether to use NTP to set the clock during the install
d-i clock-setup/ntp boolean true

### Partitioning
d-i partman-auto/disk string /dev/vda

# The presently available methods are:
# - regular: use the usual partition types for your architecture
# - lvm:     use LVM to partition the disk
# - crypto:  use LVM within an encrypted partition
d-i partman-auto/method string regular

# If one of the disks that are going to be automatically partitioned
# contains an old LVM configuration, the user will normally receive a
# warning. This can be preseeded away...
d-i partman-lvm/device_remove_lvm boolean true
# The same applies to pre-existing software RAID array:
d-i partman-md/device_remove_md boolean true
# And the same goes for the confirmation to write the lvm partitions.
d-i partman-lvm/confirm boolean true

# For LVM partitioning, you can select how much of the volume group to use
# for logical volumes.
#d-i partman-auto-lvm/guided_size string max

# You can choose one of the three predefined partitioning recipes:
# - atomic: all files in one partition
# - home:   separate /home partition
# - multi:  separate /home, /usr, /var, and /tmp partitions
d-i partman-auto/choose_recipe select atomic

# If you just want to change the default filesystem from ext3 to something
# else, you can do that without providing a full recipe.
d-i partman/default_filesystem string ext4

# This makes partman automatically partition without confirmation, provided
# that you told it what to do using one of the methods above.
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

### Base system installation
### Account setup

# To create a normal user account.
d-i passwd/user-fullname string Vagrant 
d-i passwd/username string vagrant
d-i passwd/user-password password $PASSWD
d-i passwd/user-password-again password $PASSWD
#d-i passwd/user-password-crypted password $PASSWD

# The installer will warn about weak passwords. If you are sure you know
# what you're doing and want to override it, uncomment this.
d-i user-setup/allow-password-weak boolean true

# Set to true if you want to encrypt the first user's home directory.
d-i user-setup/encrypt-home boolean false

### Apt setup
# You can choose to install restricted and universe software, or to install
# software from the backports repository.
#d-i apt-setup/restricted boolean true
#d-i apt-setup/universe boolean true
#d-i apt-setup/backports boolean true
# Uncomment this if you don't want to use a network mirror.
#d-i apt-setup/use_mirror boolean false
# Select which update services to use; define the mirrors to be used.
# Values shown below are the normal defaults.
#d-i apt-setup/services-select multiselect security
#d-i apt-setup/security_host string security.ubuntu.com
#d-i apt-setup/security_path string /ubuntu

# Additional repositories, local[0-9] available
#d-i apt-setup/local0/repository string \
#       http://local.server/ubuntu squeeze main
#d-i apt-setup/local0/comment string local server
# Enable deb-src lines
#d-i apt-setup/local0/source boolean true
# URL to the public key of the local repository; you must provide a key or
# apt will complain about the unauthenticated repository and so the
# sources.list line will be left commented out
#d-i apt-setup/local0/key string http://local.server/key

### Package selection
#tasksel	tasksel/force-tasks	string server
tasksel tasksel/first multiselect none
# Individual additional packages to install
d-i pkgsel/include string openssh-server
# Whether to upgrade packages after debootstrap.
# Allowed values: none, safe-upgrade, full-upgrade
#d-i pkgsel/upgrade select full-upgrade

# Language pack selection
d-i pkgsel/language-packs multiselect en

# No language support packages
d-i	pkgsel/install-language-support	boolean false

# Policy for applying updates. May be "none" (no automatic updates),
# "unattended-upgrades" (install security updates automatically), or
# "landscape" (manage system with Landscape).
d-i pkgsel/update-policy select none

# Verbose output and no boot splash screen
d-i	debian-installer/quiet	boolean false
d-i	debian-installer/splash	boolean false

### Boot loader installation
# This is fairly safe to set, it makes grub install automatically to the MBR
# if no other operating system is detected on the machine.
d-i grub-installer/only_debian boolean true

# This one makes grub-installer install to the MBR if it also finds some other
# OS, which is less safe as it might not be able to boot that other OS.
#d-i grub-installer/with_other_os boolean true

# Wait for two seconds in grub
d-i	grub-installer/timeout string 0

# Use the following option to add additional boot parameters for the
# installed system (if supported by the bootloader installer).
# Note: options passed to the installer will be added automatically.
#d-i debian-installer/add-kernel-opts string vga=normal nomodeset audit=0 intel_idle.max_cstate=0 processor.max_cstate=1 cgroup_enable=memory swapaccount=1

### Finishing up the installation
# Avoid that last message about the install being complete.
d-i finish-install/reboot_in_progress note

d-i debian-installer/exit/poweroff boolean true

#### Advanced options
### Running custom commands during the installation
# d-i preseeding is inherently not secure. Nothing in the installer checks
# for attempts at buffer overflows or other exploits of the values of a
# preconfiguration file like this one. Only use preconfiguration files from
# trusted locations! To drive that home, and because it's generally useful,
# here's a way to run any shell command you'd like inside the installer,
# automatically.

# This first command is run as early as possible, just after
# preseeding is read.
#d-i preseed/early_command string anna-install some-udeb
# This command is run immediately before the partitioner starts. It may be
# useful to apply dynamic partitioner preseeding that depends on the state
# of the disks (which may not be visible when preseed/early_command runs).
#d-i partman/early_command \
#       string debconf-set partman-auto/disk "$ (list-devices disk | head -n1)"
# This command is run just before the install finishes, but when there is
# still a usable /target directory. You can chroot to /target and use it
# directly, or use the apt-install and in-target commands to easily install
# packages and run commands in the target system.
#d-i preseed/late_command string in-target wget --output-document=/tmp/post-install.sh http://preseed.handsoff.local/ubuntu-16-04/post-install.sh; in-target /bin/sh /tmp/post-install.sh
d-i preseed/late_command string chroot /target bash -c "mkdir -p /root/.ssh ;\
echo '$KEYPUB' >/root/.ssh/authorized_keys ;\
mkdir -p /home/vagrant/.ssh ;\
echo '$KEYPUB' >/home/vagrant/.ssh/authorized_keys ;\
chown -R vagrant /home/vagrant/.ssh ;\
chmod 0600 /root/.ssh/authorized_keys /home/vagrant/.ssh/authorized_keys ;\
echo 'vagrant ALL=(ALL:ALL) NOPASSWD: ALL' >/etc/sudoers.d/vagrant"
XXX_END_OF_FILE_XXX
