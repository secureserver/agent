 class Rpm < FPM::Cookery::Recipe
  description 'secureserver agent'

  name 'rpm'
  version '0.0.1'

  source "nothing", :with => :noop

  platforms [:ubuntu, :debian] do
  	#potential dependencies
  end

  platforms [:fedora, :redhat, :centos] do
    #potential dependencies
  end

  def build
    #Nothing
  end

  def install
    # Install the repo file and the gpg pub key
    install_files

  end

  private

	def install_files
    etc('yum.repos.d').install workdir('../etc/secureserver.repo') => 'secureserver.repo'
    etc('pki/rpm-gpg').install workdir('../etc/pub.gpg.key') => 'RPM-GPG-KEY-secureserver'
	end

end
