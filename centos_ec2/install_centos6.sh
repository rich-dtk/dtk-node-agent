#install rvm
echo insecure >> ~/.curlrc

yum install -y wget gcc-c++ readline readline-devel zlib-devel openssl-devel make autoconf automake libtool bison rubygems

gem install puppet -v "2.7.19" --no-rdoc --no-ri
gem install grit stomp --no-rdoc --no-ri

#install mcollective
cd /tmp
wget http://downloads.puppetlabs.com/mcollective/mcollective-common-2.0.0-1.el6.noarch.rpm
rpm -i mcollective-common-2.0.0-1.el6.noarch.rpm --nodeps
wget http://downloads.puppetlabs.com/mcollective/mcollective-2.0.0-1.el6.noarch.rpm
rpm -i mcollective-2.0.0-1.el6.noarch.rpm --nodeps

#rvm wrapper 1.8.7 bootup mcollectived
#ln -s /usr/lib/ruby/site_ruby/1.8/mcollective.rb /usr/local/rvm/rubies/ruby-1.8.7-p357/lib/ruby/site_ruby/1.8/mcollective.rb
#ln -s /usr/lib/ruby/site_ruby/1.8/mcollective /usr/local/rvm/rubies/ruby-1.8.7-p357/lib/ruby/site_ruby/1.8/mcollective
