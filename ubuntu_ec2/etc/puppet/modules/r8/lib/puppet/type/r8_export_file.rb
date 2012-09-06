#
# Simple module for logging messages on the client-side
#

module Puppet
  newtype(:r8_export_file) do
    @doc = "r8 export file content"

    newparam(:name) do
      desc "component and attribute name in dot notation"
    end

    newparam(:filename) do
      desc "file name"
    end

    newproperty(:ensure) do
      desc "Whether the resource is in sync or not."

      defaultto :insync

      def retrieve
        :outofsync
      end

      newvalue :insync do
        filename = resource[:filename]
        unless File.exists?(filename)
          raise Puppet::Error, "File #{resource[:filename]} does not exist"
        end
        Puppet.send(@resource[:loglevel], "exporting #{filename} for #{resource[:name]}")
        if resource[:name] =~ /(^.+)\.(.+$)/
          cmp_name = $1
          attr_name = $2
          cmp_name.gsub!(/[.]/,"::")
          p = (Thread.current[:exported_files] ||= Hash.new)[cmp_name] ||= Hash.new
          p[attr_name] = filename
        else
          raise Puppet::Error, "ill-formed component with name (#{resource[:name]})"
        end
        return
      end
    end
  end
end
