 class PuppetGem < FPM::Cookery::Recipe
  description 'secureserver agent'

  name 'agent'
  version '0.0.1'

  source "nothing", :with => :noop

  require 'facter'

  platforms [:ubuntu, :debian] do
  	#potential dependencies
  end

  platforms [:fedora, :redhat, :centos] do
    #potential dependencies
  end

  depends 'curl'

  def build
    destdir.mkdir
    if Facter.operatingsystem == 'Debian' || Facter.operatingsystem == 'Ubuntu'
      cp "#{workdir}/../scripts/ubuntu_agent.sh", destdir('/secureserver-agent')
    elsif Facter.operatingsystem == 'CentOS' || Facter.operatingsystem == 'RedHat' || Facter.operatingsystem == 'Fedora'
      cp "#{workdir}/../scripts/rhel_agent.sh", destdir('/secureserver-agent')
    end
  end

  def install
    # Install init-script and puppet.conf
    install_files

    # Provide 'safe' binaries in /opt/<package>/bin like Vagrant does
    destdir('../bin').mkdir
    destdir('../bin').install workdir('omnibus.bin'), 'secureserver-agent'

    # Symlink binaries to PATH using update-alternatives
    with_trueprefix do
      create_post_install_hook
      create_pre_uninstall_hook
    end
  end

  private


	def install_files
    require 'debugger'; debugger
	  etc('secureserver').mkdir
    etc('secureserver').install workdir('../etc/agent.config') => 'agent.config'
	  etc('init.d').install workdir('../scripts/agent.init.sh') => 'secureserver-agent'
	  chmod 0755, etc('init.d/secureserver-agent')
	end



  def create_post_install_hook
    File.open(builddir('post-install'), 'w', 0755) do |f|
      f.write <<-__POSTINST
#!/bin/sh
set -e

BIN_PATH="#{destdir}"
BINS="secureserver-agent"

for BIN in $BINS; do
  update-alternatives --install /usr/bin/$BIN $BIN $BIN_PATH/$BIN 100
done

exit 0
      __POSTINST
    end
  end

  def create_pre_uninstall_hook
    File.open(builddir('pre-uninstall'), 'w', 0755) do |f|
      f.write <<-__PRERM
#!/bin/sh
set -e

BIN_PATH="#{destdir}"
BINS="secureserver-agent"

if [ "$1" != "upgrade" ]; then
  for BIN in $BINS; do
    update-alternatives --remove $BIN $BIN_PATH/$BIN
  done
fi

exit 0
      __PRERM
    end
  end

end
