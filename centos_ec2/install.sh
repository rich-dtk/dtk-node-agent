#install rvm
echo insecure >> ~/.curlrc

bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer )

ln -s /usr/local/rvm/bin/rvm /usr/local/bin/rvm

#yum install -y wget gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel #Find out what above is not treated

yum install -y wget gcc-c++ readline readline-devel zlib-devel openssl-devel make autoconf automake libtool bison

echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function' >> ~/.bash_profile

source  ~/.bash_profile #this might not be taking effect

#install 1.8.7 and make it the default
rvm install 1.8.7
rvm use 1.8.7 --default

rpm -Uvh http://repo.webtatic.com/yum/centos/5/latest.rpm
yum install -y --enablerepo=webtatic git

gem install grit puppet stomp --no-rdoc --no-ri

#install mcollective
cd /tmp
wget http://downloads.puppetlabs.com/mcollective/mcollective-common-1.3.2-1.el5.noarch.rpm
rpm -i mcollective-common-1.3.2-1.el5.noarch.rpm --nodeps
wget http://downloads.puppetlabs.com/mcollective/mcollective-1.3.2-1.el5.noarch.rpm
rpm -i mcollective-1.3.2-1.el5.noarch.rpm --nodeps

rvm wrapper 1.8.7 bootup mcollectived
ln -s /usr/lib/ruby/site_ruby/1.8/mcollective.rb /usr/local/rvm/rubies/ruby-1.8.7-p357/lib/ruby/site_ruby/1.8/mcollective.rb
ln -s /usr/lib/ruby/site_ruby/1.8/mcollective /usr/local/rvm/rubies/ruby-1.8.7-p357/lib/ruby/site_ruby/1.8/mcollective
