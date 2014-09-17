module DTK
  module NodeAgent
    class Installer

      # read configuration
      CONFIG = eval(File.open(File.expand_path('../config/install.config', File.dirname(__FILE__))) {|f| f.read })

      def self.run(argv)
        require 'optparse'
        require 'facter'
        require 'fileutils'
        require 'dtk-node-agent/version'

        @@options = parse(argv)

        unless Process.uid == 0
          puts "dtk-node-agent must be started with root/sudo privileges."
          exit(1)
        end

        if Facter.operatingsystem == 'Debian' || Facter.operatingsystem == 'Ubuntu'
              # set up apt and install packages
              shell "apt-get update --fix-missing"
              shell "apt-get install -y build-essential wget curl git"
              shell "wget http://apt.puppetlabs.com/puppetlabs-release-#{Facter.lsbdistcodename}.deb"
              puts "Installing Puppet Labs repository..."
              shell "dpkg -i puppetlabs-release-#{Facter.lsbdistcodename}.deb"
              shell "apt-get update"
              shell "rm puppetlabs-release-#{Facter.lsbdistcodename}.deb"
              # install mcollective
              puts "Installing MCollective..."
              shell "apt-get -y install mcollective"
            elsif Facter.operatingsystem == 'CentOS' || Facter.operatingsystem == 'RedHat'
              shell "yum -y install yum-utils wget bind-utils"
              case Facter.operatingsystemmajrelease
              when "5"
                shell "rpm -ivh #{CONFIG[:puppetlabs_el5_rpm_repo]}"
                Facter.architecture == 'X86_64' ? (shell "rpm -ivh #{CONFIG[:rpm_forge_el5_X86_64_repo]}") : (shell "rpm -ivh #{CONFIG[:rpm_forge_el5_i686_repo]}")
              when "6"
                shell "rpm -ivh #{CONFIG[:puppetlabs_el6_rpm_repo]}"
                Facter.architecture == 'X86_64' ? (shell "rpm -ivh #{CONFIG[:rpm_forge_el6_X86_64_repo]}") : (shell "rpm -ivh #{CONFIG[:rpm_forge_el6_i686_repo]}")
                shell "yum-config-manager --disable rpmforge-release"
                shell "yum-config-manager --enable rpmforge-extras"
              else
                puts "#{Facter.operatingsystem} #{Facter.operatingsystemmajrelease} is not supported. Exiting now..."
                exit(1)
              end
              puts "Installing MCollective..."
              shell "yum -y install mcollective"
              shell "chkconfig mcollective on"
              shell "yum -y install git"
              # install ec2-run-user-data init script
              # but only if the machine is running on AWS
              if `host instance-data.ec2.internal`.include? 'has address'
                FileUtils.cp("#{base_dir}/src/etc/init.d/ec2-run-user-data", "/etc/init.d/ec2-run-user-data") unless File.exist?("/etc/init.d/ec2-run-user-data")
                shell "chmod +x /etc/init.d/ec2-run-user-data"
                shell "chkconfig --level 345 ec2-run-user-data on"
              end
            else
              echo "Unsuported OS for automatic agent installation. Exiting now..."
              exit(1)
            end

            puts "Installing additions for MCollective and Puppet..."
            install_additions

          end       


          private
          
          def self.parse(argv)
            options = {}
            parser = OptionParser.new do |opts|
              opts.banner = <<-BANNER
              usage:
              
              dtk-node-agent [-p|--puppet-version] [-v|--version]
              BANNER
              opts.on("-d",
                "--debug",
                "enable debug mode")  { |v| options[:debug] = true }      
              opts.on_tail("-v",
                "--version",
                "Print the version and exit.") do
                puts ::DtkNodeAgent::VERSION
                exit(0)
              end
              opts.on_tail("-h",
                "--help",
                "Print this help message.") do
                puts parser
                exit(0)
              end
            end

            parser.parse!(argv)

            options
            
          rescue OptionParser::InvalidOption => e
            $stderr.puts e.message
            exit(12)
          end

          def self.shell(cmd)
            puts "running: #{cmd}" if @@options[:debug]
            output = `#{cmd}`
            puts output if @@options[:debug]
            if $?.exitstatus != 0
              puts "Executing command \`#{cmd}\` failed"
              puts "Command output:"
              puts output
            end
          end

          def self.install_additions
        # create puppet group
        shell "groupadd puppet" unless `grep puppet /etc/group`.include? "puppet"
        # create necessary dirs
        [   '/var/log/puppet/',
          '/var/lib/puppet/lib/puppet/indirector',
          '/etc/puppet/modules',
          '/usr/share/mcollective/plugins/mcollective'
          ].map! { |p| FileUtils.mkdir_p(p) unless File.directory?(p) }
        # copy puppet libs
        FileUtils.cp_r(Dir.glob("#{base_dir}/puppet_additions/puppet_lib_base/puppet/indirector/*"), "/var/lib/puppet/lib/puppet/indirector/")
        # copy r8 puppet module
        FileUtils.cp_r(Dir.glob("#{base_dir}/puppet_additions/modules/r8"), "/etc/puppet/modules")
        # copy mcollective plugins
        FileUtils.cp_r(Dir.glob("/usr/libexec/mcollective/mcollective/*"), "/usr/share/mcollective/plugins/mcollective") if File.directory?("/usr/libexec/mcollective/")        
        FileUtils.cp_r(Dir.glob("#{base_dir}/mcollective_additions/plugins/v#{CONFIG[:mcollective_version]}/*"), "/usr/share/mcollective/plugins/mcollective")

        # copy mcollective config
        FileUtils.cp_r("#{base_dir}/mcollective_additions/server.cfg", "/etc/mcollective", :remove_destination => true)

        # copy compatible mcollective init script
        FileUtils.cp_r("#{base_dir}/mcollective_additions/#{Facter.osfamily.downcase}.mcollective.init", "/etc/init.d/mcollective", :remove_destination => true)
      end

      def self.base_dir
        File.expand_path('../..', File.dirname(__FILE__))
      end

    end
  end
end