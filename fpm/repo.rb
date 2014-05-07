class RpmRepo < FPM::Cookery::Recipe
  homepage 'https://github.com/secureserver/agent'

  section 'Utilities'
  name 'secureserver-repo'
  version '1'
  description 'secureserver rpm repo package'
  revision 0
  vendor 'fpm'
  arch    'noarch'
  maintainer '<dario.duvnjak@gmail.com>'
  license 'MIT License'

  source '', :with => :noop

  omnibus_package true
  omnibus_dir     ""
  omnibus_recipes 'rpm'

  # Set up paths to the repo file and the gpg key
  config_files '/etc/yum.repos.d/secureserver.repo',
               '/etc/pki/rpm-gpg/RPM-GPG-KEY-secureserver'

  omnibus_additional_paths config_files

  def build
    # Nothing
  end

  def install
    # Nothing
  end

end
