# load the .env file to add user overrides
if File.exists?(File.join(File.dirname(__FILE__), '.env'))
  begin
    require 'dotenv'

    Dotenv.load(File.join(File.dirname(__FILE__), '.env'))
  rescue LoadError => e
    $stderr.puts <<-ERR
Could not load ".env" file because "dotenv" gem is missing.
Install it via "vagrant plugin" or "gem":

- vagrant plugin install vagrant-env
- gem install dotenv

    ERR
  end
end

Vagrant.configure('2') do |config|
  config.vm.box = 'generic/ubuntu2204'

  # detect the host platform and retrieve system resources to allow sane
  # defaults without exceeding the machine specification; the detected
  # platform will also be used to determine how the codebase is mounted
  # to the virtual machine
  if RbConfig::CONFIG['host_os'] =~ /linux/
    host_platform = 'linux'
    host_cpu = `nproc`.to_i
    host_mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024
  elsif RbConfig::CONFIG['host_os'] =~ /darwin/
    host_platform = 'darwin'
    host_cpu = `sysctl -n hw.ncpu`.to_i
    host_mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024
  else
    host_platform = 'windows'
    host_cpu = `wmic cpu get NumberOfCores`.split("\n")[2].to_i
    host_mem = `wmic OS get TotalVisibleMemorySize`.split("\n")[2].to_i / 1024
  end

  config.ssh.forward_agent = true
  config.ssh.forward_x11 = true

  config.vm.synced_folder './', '/vagrant', type: :nfs, nfs_version: 4, nfs_udp: false, mount_options: %w[rw actimeo=2 async noatime]

  config.vm.provider :libvirt do |v|
    v.memory = ENV['VAGRANT_MEMORY'] || [1536, host_mem / 4].min
    v.cpus = ENV['VAGRANT_CPUS'] || host_cpu
    v.nested = true
    v.keymap = ENV['VAGRANT_KEYMAP'] || 'en-gb'
    v.machine_virtual_size = (ENV['VAGRANT_DISKSIZE'] || '128GB').to_i

    # graphical
    v.sound_type = 'ich6'
    v.channel :type => 'unix', :target_name => 'org.qemu.guest_agent.0', :target_type => 'virtio'
    v.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
    v.graphics_type = 'spice'
    v.video_type = 'qxl'

    # vagrant-libvirt does not support 3d acceleration with spice see #1482,
    # however, qxl reports higher fps in glxgears than virtio on a i7-1065G7
    # with x11 host and guest sessions so may be preferred
    # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1482
    #v.graphics_gl = true
    #v.graphics_ip = nil
    #v.video_type = 'virtio'
    #v.video_accel3d = true

    v.redirdev :type => 'spicevmc'
  end

  config.vm.provider 'virtualbox' do |v, override|
    v.memory = ENV['VAGRANT_MEMORY'] || [1536, host_mem / 4].min
    v.cpus = ENV['VAGRANT_CPUS'] || host_cpu
    v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    v.customize ['guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold', 10000]

    # graphical
    v.gui = true
    v.customize ['modifyvm', :id, '--graphicscontroller', 'vmsvga']
    v.customize ['modifyvm', :id, '--clipboard', 'bidirectional']

    if Vagrant.has_plugin?('vagrant-disksize')
      config.disksize.size = ENV['VAGRANT_DISKSIZE'] || '128GB'
    end
  end

  if Vagrant.has_plugin?('vagrant-cachier')
    config.cache.scope = :box
    config.cache.synced_folder_opts = { type: :nfs, nfs_version: 4, nfs_udp: false, mount_options: %w[rw actimeo=2 async noatime] }
  end

  # resize root partition to 100% of disk size
  config.vm.provision 'parted', type: 'shell', :run => 'once', :privileged => true, inline: <<-'EOF'
    DISK=$(mount | awk '$3 == "/" { print $1 }')
    if [[ "$DISK" == */mapper/* ]]; then
      MAPPER="$DISK"
      DISK=$(lvs --segments "$MAPPER" -o devices | awk '$1 ~ "/dev" { print $1 }' | head -n1 | sed -E 's/\(.+//')
      DEVICE=$(echo "$DISK" | sed -E 's/p?[0-9]+$//')
      PARTITION=$(echo "$DISK" | sed -nE 's/.*([0-9]+)$/\1/p')
      parted "$DEVICE" resizepart "$PARTITION" 100%
      pvresize "$DISK"
      lvextend -l +100%FREE "$MAPPER"
      resize2fs "$MAPPER"
    else
      DEVICE=$(echo "$DISK" | sed -E 's/p?[0-9]+$//')
      PARTITION=$(echo "$DISK" | sed -nE 's/.*([0-9]+)$/\1/p')
      parted "$DEVICE" resizepart "$PARTITION" 100%
      resize2fs "$DISK"
    fi
  EOF

  config.vm.provision 'gdm', type: 'shell', :run => 'once', :privileged => true, inline: <<-'EOF'
    #!/bin/bash
    set -euo pipefail

    # add default groups when installing from ubuntu-desktop iso
    for group in adm cdrom sudo dip plugdev; do
      adduser vagrant "$group"
    done

    # install ubuntu-desktop
    export DEBIAN_FRONTEND=noninteractive
    apt update -qqy
    apt install -qqy ubuntu-desktop language-pack-gnome-en

    # install firefox
    sudo snap install firefox

    # force Xorg login screen
    sed -i -E 's/^#(WaylandEnable=false)/\1/' /etc/gdm3/custom.conf

    cat <<'XSESSION' >/var/lib/AccountsService/users/vagrant
[User]
Session=ubuntu-xorg
Icon=/home/vagrant/.face
SystemAccount=false

[InputSource0]
xkb=gb
XSESSION

    # hide welcome screen
    su -s /bin/bash vagrant -c '([[ -d ~/.config ]] || mkdir ~/.config) && /bin/echo -n yes >~/.config/gnome-initial-setup-done'

    # start gnome display manager
    systemctl start gdm
  EOF

  config.vm.provision 'ansible', type: :ansible_local do |ansible|
    ansible.playbook = 'site.yml'
  end
end
