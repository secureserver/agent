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
  end

  private

  def install_files
    etc('secureserver').mkdir
    etc('secureserver').install workdir('../etc/agent.config') => 'agent.config'
    if Facter.operatingsystem == 'Debian' || Facter.operatingsystem == 'Ubuntu'
      etc('init.d').install workdir('../scripts/ubuntu_agent.init') => 'secureserver-agent'
    elsif Facter.operatingsystem == 'CentOS' || Facter.operatingsystem == 'RedHat' || Facter.operatingsystem == 'Fedora'
      etc('init.d').install workdir('../scripts/rhel_agent.init') => 'secureserver-agent'
    end
    chmod 0755, etc('init.d/secureserver-agent')
  end
end
