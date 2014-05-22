class SecureserverAgent < FPM::Cookery::Recipe
  homepage 'https://github.com/secureserver/agent'

  section 'Utilities'
  name 'secureserver-agent'
  version '0.0.1'
  description 'secureserver agent package'
  revision 0
  arch    'noarch'
  maintainer '<dario.duvnjak@gmail.com>'
  license 'MIT License'

  source '', :with => :noop

  omnibus_package true
  omnibus_dir     "/opt/#{name}"
  omnibus_recipes 'agent'

  # Set up paths to initscript and config files per platform
  config_files '/etc/init.d/secureserver-agent',
               '/etc/secureserver/agent.config'

  omnibus_additional_paths config_files

  platforms [:fedora, :redhat, :centos] do
    build_depends 'rpmdevtools'
  end

  platforms [:ubuntu, :debian] do
    post_install '../scripts/ubuntu_agent.postinst'
    pre_uninstall '../scripts/ubuntu_agent.prerm'
  end

  platforms [:fedora, :redhat, :centos] do
    post_install '../scripts/rhel_agent.postinst'
    pre_uninstall '../scripts/rhel_agent.prerm'
  end

  def build
    # Nothing
  end

  def install
    # Nothing
  end
end
