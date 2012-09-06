cd /tmp
yum install -y gcc zlib zlib-devel
wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p358.tar.gz
tar xvf ruby-1.8.7-p358.tar.gz
cd ruby-1.8.7-p358
./configure --enable-pthread
make
make install

wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
tar -zxvf rubygems-1.3.7.tgz
cd rubygems-1.3.7
ruby setup.rb config
ruby setup.rb setup
ruby setup.rb install
gem install grit puppet stomp --no-rdoc --no-ri

cd /tmp
wget http://download.fedora.redhat.com/pub/epel/5/i386/rubygem-stomp-1.1.8-1.el5.noarch.rpm
rpm -i rubygem-stomp-1.1.8-1.el5.noarch.rpm --nodeps

cd /tmp
wget  http://puppetlabs.com/downloads/mcollective/mcollective-common-1.2.1-1.el5.noarch.rpm
rpm -i mcollective-common-1.2.1-1.el5.noarch.rpm -nodeps
wget  http://puppetlabs.com/downloads/mcollective/mcollective-1.2.1-1.el5.noarch.rpm
rpm -i mcollective-1.2.1-1.el5.noarch.rpm --nodeps
