class SecureserverAgent < FPM::Cookery::Recipe
  homepage 'https://github.com/andytinycat/puppet-omnibus'

  section 'Utilities'
  name 'secureserver-agent'
  version '0.0.1'
  description 'secureserver Agent package'
  revision 0
  vendor 'fpm'
  arch    'noarch'
  maintainer '<dario.duvnjak@gmail.com>'
  license 'MIT License'

  source '', :with => :noop

  omnibus_package true
  omnibus_dir     "/opt/#{name}"
  omnibus_recipes 'agent'

  # Set up paths to initscript and config files per platform
  config_files '/etc/init.d/secureserver-agent'

  omnibus_additional_paths config_files

  def build
    # Nothing
  end

  def install
    # Set paths to package scripts
    self.class.post_install builddir('post-install')
    self.class.pre_uninstall builddir('pre-uninstall')
  end

end