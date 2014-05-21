class PuppetGem < FPM::Cookery::Recipe
  description 'secureserver agent'

  name 'agent'
  version '0.0.1'

  source "nothing", :with => :noop

  require 'facter'

  platforms [:ubuntu, :debian] do
    # Potential dependencies
  end

  platforms [:fedora, :redhat, :centos] do
    # Potential dependencies
  end

  depends 'curl'

  def build
    destdir.mkdir
    if Facter.operatingsystem == 'Debian' || Facter.operatingsystem == 'Ubuntu'
      cp "#{workdir}/../scripts/ubuntu_agent.sh", destdir('/secureserver-agent')
    elsif Facter.operatingsystem == 'CentOS' || Facter.operatingsystem == 'RedHat' || Facter.operatingsystem == 'Fedora'
      cp "#{workdir}/../scripts/rhel_agent.sh", destdir('/secureserver-agent')
    end
    # Install the config script
    cp "#{workdir}/../scripts/secureserver-config.sh", destdir('/secureserver-config')
  end

  def install
    # Install init-script and puppet.conf
    install_files

    # Provide 'safe' binaries in /opt/<package>/bin like Vagrant does
    destdir('../bin').mkdir
    destdir('../bin').install workdir('omnibus.bin'), 'secureserver-agent'
    destdir('../bin').install workdir('omnibus.bin'), 'secureserver-config'

    # Symlink binaries to PATH using update-alternatives
    with_trueprefix do
      create_post_install_hook
      create_pre_uninstall_hook
    end
  end

  private

  def install_files
    etc('secureserver').mkdir
    etc('secureserver').install workdir('../etc/agent.config') => 'agent.config'
    if Facter.operatingsystem == 'Debian' || Facter.operatingsystem == 'Ubuntu'
      etc('init.d').install workdir('../scripts/ubuntu_agent.init.sh') => 'secureserver-agent'
    elsif Facter.operatingsystem == 'CentOS' || Facter.operatingsystem == 'RedHat' || Facter.operatingsystem == 'Fedora'
      etc('init.d').install workdir('../scripts/rhel_agent.init.sh') => 'secureserver-agent'
    end
    chmod 0755, etc('init.d/secureserver-agent')
  end

  def create_post_install_hook
    File.open(builddir('post-install'), 'w', 0755) do |f|
      f.write <<-__POSTINST
#!/bin/sh
set -e

bin_path="#{destdir}"
bins="secureserver-agent secureserver-config"
user="secureserver"
group="secureserver"

if [ "$1" = "configure" ]
then
    for bin in $bins
    do
        update-alternatives --install /usr/bin/"$bin" "$bin" "$bin_path"/"$bin" 100
    done

    if ! getent group "$group" > /dev/null 2>&1
    then
        echo "Adding new group '$group' ..."
        groupadd --system "$group"
    fi

    if ! id "$user" > /dev/null 2>&1
    then
        echo "Adding new user '$user' with group '$group' ..."
        useradd --system --no-create-home --gid "$group" --shell /bin/false "$user"
    fi
fi

# Only if upstart isn't in charge
if ! { [ -x /sbin/initctl ] && /sbin/initctl version 2>/dev/null | grep -q upstart; }
then
    update-rc.d secureserver-agent defaults > /dev/null || true
fi

if [ -n "$2" ]
then
    action=restart
else
    action=start
fi

service secureserver-agent $action 2>/dev/null || true

exit 0
      __POSTINST
    end
  end

  def create_pre_uninstall_hook
    File.open(builddir('pre-uninstall'), 'w', 0755) do |f|
      f.write <<-__PRERM
#!/bin/sh
set -e

bin_path="#{destdir}"
bins="secureserver-agent secureserver-config"
user="secureserver"
group="secureserver"

if [ "$1" != "upgrade" ]
then
    service secureserver-agent stop || true
    for bin in $bins; do
        update-alternatives --remove "$bin" "$bin_path"/"$bin"
    done
    echo "Removing user '$user'  ..."
    userdel "$user" || true
fi

exit 0
      __PRERM
    end
  end
end
