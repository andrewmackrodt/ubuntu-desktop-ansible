# Ubuntu 24.04 Desktop Ansible Provisioner

## Requirements

Install ansible:

```sh
sudo apt install ansible
```

Install externally hosted roles from requirements.yml:

```sh
ansible-galaxy install -r requirements.yml
```

## Customization

Create the file `./host_vars/localhost.yml` with your machine specific customizations.

#### Replacing dict values

Due to the deprecation of `hash_behaviour = merge`, some dicts explicitly use the `combine` filter.
These vars are suffixed with `_defaults`, e.g. `gnome_background_defaults`. To replace a value,
remove the `_defaults` prefix when setting vars, e.g. `gnome_background`.

Example `host_vars` file:

```yaml
locale: en_US.UTF-8
localrtc: 0
timezone: America/New_York

# replace single value in dict
gnome_background:
  picture-uri: "'file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png'"
```

## Provisioning

### local

Run against local machine:

```sh
ansible-playbook site.yml -i local --ask-become-pass 
```

### vagrant

Install libvirt and virt-manager:

```sh
sudo apt install qemu-kvm virt-manager libvirt-daemon-system virtinst libvirt-clients dnsmasq-base libguestfs-tools nfs-kernel-server
sudo systemctl enable libvirtd --now
sudo adduser $(whoami) libvirt
```

Log out and log in to apply new groups before continuing.

Install vagrant and required plugins:

```sh
sudo apt install vagrant build-essential libvirt-dev ruby-libvirt
vagrant plugin install vagrant-env
vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-vbguest
```

Copy `.env.sample` to `.env` and make any modifications:

```sh
cp .env.sample .env
editor .env
```

Start virtual machine using vagrant:

```sh
vagrant up
```

To re-run the ansible playbook:

```sh
vagrant provision --provision-with ansible
```
