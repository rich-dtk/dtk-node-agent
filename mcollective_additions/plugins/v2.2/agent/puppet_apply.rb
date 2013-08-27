#!/usr/bin/env ruby
require 'rubygems'
require 'puppet'
require 'grit'
require 'tempfile'
require 'fileutils'

#dont want to run standard hooks and just want store configs for catalogs/resources, not for facts ..
Puppet.settings.set_value(:storeconfigs,true,:memory, :dont_trigger_handles => true)
Puppet::Resource::Catalog.indirection.cache_class = :store_configs
Puppet::Resource.indirection.terminus_class = :store_configs

#TODO: move to be shared by agents
PuppetApplyLogDir = "/var/log/puppet"
ModulePath =  "/etc/puppet/modules"

module MCollective
  module Agent
    class Puppet_apply < RPC::Agent
      def initialize()
        super()
        @log = Log.instance
        @reply_data = nil
      end

      def run_action
        #validate :components_with_attributes
        #validate :version_context
        #validate :node_manifest
        #validate :task_id, Fixnum
        #validate :top_task_id, Fixnum

        log_params()
        @reply_data = nil
        @msg_id = request.uniqid
        @task_info = [:task_id,:top_task_id].inject({}) do |h,k|
          h.merge(k => request[k])
        end.merge(:msg_id => @msg_id)

        more_generic_response = Response.new()
        puppet_run_response = nil
        begin
          response = pull_recipes(request[:version_context])
          return set_reply!(response) if response.failed?()
          puppet_run_response = run(request)
        rescue Exception => e
          more_generic_response.set_status_failed!()
          error_info = {
            :error => {
              :message => e.inspect
            }
          }
          more_generic_response.merge!(error_info)
        end
        set_reply?(puppet_run_response || more_generic_response)
      end
     private

      #TODO: this should be common accross Agents after pulling out aagent specfic params
      def pull_recipes(version_context)
        ret = Response.new
        ENV['GIT_SHELL'] = nil #This is put in because if vcsrepo Puppet module used it sets this
        begin
          version_context.each do |vc|
            repo = vc[:repo]
            implementation = vc[:implementation]
            branch_name = vc[:branch]
            repo_dir = "#{ModulePath}/#{implementation}"
            unless File.exists?(repo_dir)
              begin
                raise "git server is not set in facts" unless git_server = Facts["git-server"]
                remote_git = "#{git_server}:#{repo}"
                ClientRepo.clone(remote_git,repo_dir)
               rescue Exception => e
                #to achive idempotent behavior fully remove directory that has not been fully cloned
                FileUtils.rm_rf repo_dir
                raise e
              end
            end
            Dir.chdir(repo_dir) do
              begin 
                repo = ClientRepo.new(".")
                if repo.branch_exists?(branch_name)
                  current_branch = repo.current_branch
                  repo.git_command__checkout(branch_name) unless current_branch == branch_name
                  repo.git_command__pull(branch_name)
                else
                  unless repo.remote_branch_exists?("origin/#{branch_name}")
                    repo.git_command__pull()
                  end
                  repo.git_command__checkout_track_branch(branch_name)
                end
              end
            end
          end
          ret.set_status_succeeded!()
         rescue Exception => e
          ret.set_status_failed!()
          error_info = {
            :error => {
              :message => e.inspect
            }
          }
          ret.merge!(error_info)
         ensure
          #TODO: may mot be needed now switch to grit
          #git library sets these vars; so resting here
          %w{GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE}.each{|var|ENV[var]=nil}
        end
        ret 
      end

      def run(request)
        cmps_with_attrs = request[:components_with_attributes]
        node_manifest = request[:node_manifest]
        inter_node_stage = request[:inter_node_stage]
        puppet_version = request[:puppet_version]

        if puppet_version
          @log.info("Setting user provided puppet version '#{puppet_version}'") 
          puppet_version = "_#{puppet_version}_"
        end

        # Amar: Added task ID to current thread, so puppet apply can be canceled from puppet_cancel.rb when user requests cancel
        task_id = request[:top_task_id]
        Thread.current[:task_id] = task_id

        clean_state()
        ret = nil
        log_file_path = log_file_path()
        log_file = nil
        begin
          save_stderr = nil
          stderr_capture = nil
          log_file = File.open(log_file_path,"a")
          log_file.close
          Puppet[:autoflush] = true
          most_recent_link = most_recent_file_path()
          File.delete(most_recent_link) if File.exists? most_recent_link
          File.symlink(log_file_path,most_recent_link)

          # Amar: Node manifest contains list of generated puppet manifests
          #       This is done to support multiple puppet calls inside one puppet_apply agent call
          node_manifest.each_with_index do |puppet_manifest, i|
            execute_lines = puppet_manifest || ret_execute_lines(cmps_with_attrs)
            execute_string = execute_lines.join("\n")
            @log.info("\n----------------execute_string------------\n#{execute_string}\n----------------execute_string------------")
            File.open("/tmp/site_stage#{inter_node_stage}_puppet_invocation_#{i+1}.pp","w"){|f| f << execute_string}
            cmd_line = 
              [
               "apply", 
               "-l", log_file_path, 
               "-d", 
               "--report", true, "--reports", "r8report",
               "--storeconfigs_backend", "r8_storeconfig_backend",
               "-e", execute_string
              ]
            cmd = "/usr/bin/puppet" 
            save_stderr = $stderr
            stderr_capture = Tempfile.new("stderr")
            $stderr = stderr_capture
            begin
              Puppet::Node::Environment.clear()
              Thread.current[:known_resource_types] = nil #TODO: when move up to later versions of puupet think can remove because Puppet::Node::Environment.clear() does this
              Puppet::Util::CommandLine.new(cmd,cmd_line).execute
            rescue SystemExit => exit
              report_status = Report::get_status()
              report_info = Report::get_report_info()
              # For multiple puppet calls, if one fails, rest will not get executed
              raise exit if report_status == :failed || report_info[:errors] || (i == node_manifest.size - 1)
            end
          end
         rescue SystemExit => exit
          report_status = Report::get_status()
          report_info = Report::get_report_info()
          exit_status = exit.status
          @log.info("exit.status = #{exit_status}")
          @log.info("report_status = #{report_status}")
          @log.info("report_info = #{report_info.inspect}")
          return_code = ((report_status == :failed || report_info[:errors]) ? 1 : exit_status)
          ret ||= Response.new()
          if return_code == 0
            if dynamic_attributes = process_dynamic_attributes?(cmps_with_attrs)
              @log.info("dynamic_attributes = #{dynamic_attributes.inspect}")
              ret.set_dynamic_attributes!(dynamic_attributes)
            end
            ret.set_status_succeeded!()
          else
            ret.set_status_failed!()
            error_info = {
              :return_code => return_code            
            }
            error_info.merge!(:errors => report_info[:errors]) if (report_info||{})[:errors]
            error_info[:errors].each { |error| error["type"] = "user_error" } if error_info[:errors]
            ret.merge!(error_info)
          end
         rescue Exception => e
          pp [e,e.backtrace[0..5]]
          log_error = ([e.inspect]+[e.backtrace[0..5]]).join("\n")
          @log.info("\n----------------error-----\n#{log_error}\n----------------error-----")
          ret ||= Response.new()
          ret.set_status_failed!()
          error_info = {
            :error => {
              :message => e.inspect
            }
          }
          ret.merge!(error_info)
         ensure
          # Amar: If puppet_apply thread was killed from puppet_cancel, ':is_canceled' flag is set on the thread, 
          # so puppet_apply can send status canceled in the response
          ret ||= Response.new()
          if Thread.current[:is_canceled]
            @log.info("Setting cancel status...")
            ret.set_status_canceled!()
            return set_reply!(ret)
          end
          if save_stderr #test if this is nil as to whether did the stderr swap
            $stderr = save_stderr
            stderr_capture.rewind
            stderr_msg = stderr_capture.read
            stderr_capture.close
            stderr_capture.unlink
            if stderr_msg and not stderr_msg.empty?
              ret[:errors] = (ret[:errors]||[]) + [{:message => stderr_msg, :type => "user_error" }]
              ret.set_status_failed!()
              Puppet::err stderr_msg 
              Puppet::info "(end)"
            end
          end
          Puppet::Util::Log.close_all()
        end
        ret 
      end

      #TODO: cleanup fn; need to fix on serevr side; inconsient use of symbol and string keys 
      #execute_lines
      def ret_execute_lines(cmps_with_attrs)
        ret = Array.new
        @import_statement_modules = Array.new
        cmps_with_attrs.each_with_index do |cmp_with_attrs,i|
          stage = i+1
          module_name = cmp_with_attrs["module_name"]
          ret << "stage{#{quote_form(stage)} :}"
          attrs = process_and_return_attr_name_val_pairs(cmp_with_attrs)
          stage_assign = "stage => #{quote_form(stage)}"
          case cmp_with_attrs["component_type"]
           when "class"
            cmp = cmp_with_attrs["name"]
            raise "No component name" unless cmp
            if imp_stmt = needs_import_statement?(cmp,module_name)
              ret << imp_stmt 
            end

            #TODO: see if need \" and quote form
            attr_str_array = attrs.map{|k,v|"#{k} => #{process_val(v)}"} + [stage_assign]
            attr_str = attr_str_array.join(", ")
            ret << "class {\"#{cmp}\": #{attr_str}}"
           when "definition"
            defn = cmp_with_attrs["name"]
            raise "No definition name" unless defn
            name_attr = nil
            attr_str_array = attrs.map do |k,v|
              if k == "name"
                name_attr = quote_form(v)
                nil
              else
                "#{k} => #{process_val(v)}"
              end
            end.compact
            attr_str = attr_str_array.join(", ")
            raise "No name attribute for definition" unless name_attr
            if imp_stmt = needs_import_statement?(defn,module_name)
              ret << imp_stmt
            end
            #putting def in class because defs cannot go in stages
            class_wrapper = "stage#{stage.to_s}"
            ret << "class #{class_wrapper} {"
            ret << "#{defn} {#{name_attr}: #{attr_str}}"
            ret << "}"
            ret << "class {\"#{class_wrapper}\": #{stage_assign}}"
          end
        end
        size = cmps_with_attrs.size
        if size > 1
          ordering_statement = (1..cmps_with_attrs.size).map{|s|"Stage[#{s.to_s}]"}.join(" -> ")
          ret << ordering_statement
        end

        if attr_val_stmts = get_attr_val_statements(cmps_with_attrs)
          ret += attr_val_stmts
        end
        ret
      end

      #removes imported collections and puts them on global array
      def process_and_return_attr_name_val_pairs(cmp_with_attrs)
        ret = Hash.new
        return ret unless attrs = cmp_with_attrs["attributes"]
        cmp_name = cmp_with_attrs["name"]
        attrs.each do |attr_info|
          attr_name = attr_info["name"]
          val = attr_info["value"]
          case attr_info["type"] 
           when "attribute"
            ret[attr_name] = val
          when "imported_collection"
            add_imported_collection(cmp_name,attr_name,val,{"resource_type" => attr_info["resource_type"], "import_coll_query" =>  attr_info["import_coll_query"]})
          else raise "unexpected attribute type (#{attr_info["type"]})"
          end
        end
        ret
      end

      def get_attr_val_statements(cmps_with_attrs)
        ret = Array.new
        cmps_with_attrs.each do |cmp_with_attrs|
          (cmp_with_attrs["dynamic_attributes"]||[]).each do |dyn_attr|
            if dyn_attr[:type] == "default_variable"
              qualified_var = "#{cmp_with_attrs["name"]}::#{dyn_attr[:name]}"
              ret << "r8::export_variable{'#{qualified_var}' :}"
            end
          end
        end
        ret.empty? ? nil : ret
      end

      
      def needs_import_statement?(cmp_or_def,module_name)
        return nil if cmp_or_def =~ /::/
        return nil if @import_statement_modules.include?(module_name)
        @import_statement_modules << module_name
        "import '#{module_name}'"
      end

      def process_val(val)
        #a guarded val
        if val.kind_of?(Hash) and val.size == 1 and val.keys.first == "__ref"
          "$#{val.values.join("::")}"
        else
          quote_form(val)
        end
      end

      def process_dynamic_attributes?(cmps_with_attrs)
        ret = Array.new
        cmps_with_attrs.each do |cmp_with_attrs|
          dyn_attrs = cmp_with_attrs["dynamic_attributes"]
          if dyn_attrs and not dyn_attrs.empty?
            cmp_ref = component_ref(cmp_with_attrs)
            dyn_attrs.each do |dyn_attr|
              if el = dynamic_attr_response_el(cmp_ref,dyn_attr)
                ret << el
              end
            end
          end
        end
        ret.empty? ? nil : ret
      end
      def dynamic_attr_response_el(cmp_name,dyn_attr)
        ret = nil
        val = 
          if dyn_attr[:type] == "exported_resource" 
            dynamic_attr_response_el__exported_resource(cmp_name,dyn_attr)
          elsif dyn_attr[:type] == "default_variable"
            dynamic_attr_response_el__default_attribute(cmp_name,dyn_attr)
          else #assumption only three types: "exported_resource", "default_attribute, (and other can by "dynamic")
            dynamic_attr_response_el__default_attribute(cmp_name,dyn_attr)||dynamic_attr_response_el__dynamic(cmp_name,dyn_attr)
          end
        if val
          ret = {
            :component_name => cmp_name,
            :attribute_name => dyn_attr[:name],
            :attribute_id => dyn_attr[:id],
            :attribute_val => val
          }
        end
        ret
      end

      def dynamic_attr_response_el__exported_resource(cmp_name,dyn_attr)
        ret = nil 
        if cmp_exp_rscs = exported_resources(cmp_name)
          cmp_exp_rscs.each do |title,val|
            return val if exp_rsc_match(title,dyn_attr[:title_with_vars])
          end
        else
          @log.info("no exported resources set for component #{cmp_name}")
        end
        ret
      end

      #TODO: more sophistiacted would take var bindings
      def exp_rsc_match(title,title_with_vars)
        regexp_str = regexp_string(title_with_vars)
        @log.info("debug: regexp_str = #{regexp_str}")
        title =~ Regexp.new("^#{regexp_str}$") if regexp_str
      end

      def regexp_string(title_with_vars)
        if title_with_vars.kind_of?(Array)
          case title_with_vars.first 
          when "variable" then ".+"
          when "fn" then regexp_string__when_op(title_with_vars)
          else
            @log.info("unexpected first element in title with vars (#{title_with_vars.first})")
            nil
          end
        else
          title_with_vars.gsub(".","\\.")
        end
      end

      def regexp_string__when_op(title_with_vars)
        unless title_with_vars[1] == "concat"
          @log.info("not treating operation (#{title_with_vars[1]})")
          return nil
        end
        title_with_vars[2..title_with_vars.size-1].map do |x|
          return nil unless re = regexp_string(x)
          re
        end.join("")
      end

      def dynamic_attr_response_el__dynamic(cmp_name,dyn_attr)
        ret = nil
        attr_name = dyn_attr[:name]
        filepath = (exported_files(cmp_name)||{})[attr_name]
        #TODO; legacy; remove when deprecate 
        filepath ||= "/tmp/#{cmp_name.gsub(/::/,".")}.#{attr_name}"
        begin
          val = File.open(filepath){|f|f.read}.chomp
          ret = val unless val.empty?
         rescue Exception
        end
        ret
      end

      def dynamic_attr_response_el__default_attribute(cmp_name,dyn_attr)
        ret = nil
        unless cmp_exp_vars = exported_variables(cmp_name)
          @log.info("no exported varaibles for component #{cmp_name}")
          return ret
        end
        
        attr_name = dyn_attr[:name]
        unless cmp_exp_vars.has_key?(attr_name)
          @log.info("no exported variable entry for component #{cmp_name}, attribute #{dyn_attr[:name]})")
          return ret
        end

        cmp_exp_vars[attr_name]
      end

      def clean_state()
        [:exported_resources, :exported_variables, :report_status, :imported_collections].each do |k|
          Thread.current[k] = nil if Thread.current.keys.include?(k)
        end
      end
      def exported_resources(cmp_name)
        (Thread.current[:exported_resources]||{})[cmp_name]
      end
      def exported_variables(cmp_name)
        (Thread.current[:exported_variables]||{})[cmp_name]
      end
      def exported_files(cmp_name)
        (Thread.current[:exported_files]||{})[cmp_name]
      end
      def add_imported_collection(cmp_name,attr_name,val,context={})
        p = (Thread.current[:imported_collections] ||= Hash.new)[cmp_name] ||= Hash.new
        p[attr_name] = {"value" => val}.merge(context)
      end

      def component_ref(cmp_with_attrs)
        case cmp_with_attrs["component_type"]
        when "class"
          cmp_with_attrs["name"]
        when "definition"
          defn = cmp_with_attrs["name"]
          name_attr_val = (cmp_with_attrs["attributes"].find{|attr|attr["name"]}||{})["value"]
          raise "Cannot find the name associated with definition #{defn}" unless name_attr_val
          "#{cmp_with_attrs["name"]}[#{name_attr_val}]"
        else
          raise "Reference to type #{cmp_with_attrs["component_type"]} not treated"
        end
      end

      def self.capitalize_resource_name(name)
        name.split('::').map{|p|p.capitalize}.join("::")
      end
      def capitalize_resource_name(name)
        self.class.capitalize_resource_name(name)
      end

      DynamicVarDefName = "r8_dynamic_vars::set_var"
      DynamicVarDefNameRN = capitalize_resource_name(DynamicVarDefName)

      def quote_form(obj)
        if obj.kind_of?(Hash) 
          "{#{obj.map{|k,v|"#{quote_form(k)} => #{quote_form(v)}"}.join(",")}}"
        elsif obj.kind_of?(Array)
          "[#{obj.map{|el|quote_form(el)}.join(",")}]"
        elsif obj.kind_of?(String)
          "\"#{obj}\""
        elsif obj.nil?
          "nil"
        else
          obj.to_s
        end
      end

      def set_reply!(response)
        reply.data = @reply_data = response.to_hash
      end
      def set_reply?(response)
        reply.data = @reply_data ||= response.to_hash
      end
      def log_params()
        @log.info("params: #{request.data.inspect}")
      end
      
      def log_file_path()
        "#{PuppetApplyLogDir}/#{id_info()}.log"
      end
      def most_recent_file_path()
        "#{PuppetApplyLogDir}/last.log"
      end
      def id_info()
        [:msg_id,:task_id,:top_task_id].map do |k|
          if @task_info.has_key?(k)
            "#{k}:#{@task_info[k].to_s}"
          end
        end.compact.join(":")
      end

      #TODO: this should be common accross Agents
      class ClientRepo
        def self.clone(remote_git,repo_dir)
          Grit::Git.new("").clone(git_command_opts(),remote_git,repo_dir)
        end
        def initialize(path)
          @path = path
          @grit_repo = Grit::Repo.new(path)
          @index = @grit_repo.index #creates new object so use @index, not grit_repo
        end
        
        def branch_exists?(branch_name)
          @grit_repo.heads.find{|h|h.name == branch_name} ? true : nil
        end
        
        def remote_branch_exists?(branch_name)
          @grit_repo.remotes.find{|h|h.name == branch_name} ? true : nil
        end
        
        def git_command__checkout_track_branch(branch_name)
          git_command().checkout(git_command_opts(),"--track","-b", branch_name, "origin/#{branch_name}")
        end

        def current_branch()
          @grit_repo.head.name
        end
  
        def git_command__checkout(branch_name) 
          git_command().checkout(git_command_opts(),branch_name)
        end
        
        def git_command__pull(branch_name=nil)
          branch_name ? git_command().pull(git_command_opts(),"origin",branch_name) : git_command().pull(git_command_opts(),"origin")
        end
       private
        def self.git_command_opts()
          {:raise => true, :timeout => 60}
        end
        def git_command_opts()
          self.class.git_command_opts()
        end
        def git_command()
          @grit_repo.git
        end
      end

      #TODO: this should be common accross Agents
      class Response < Hash
        def initialize(hash={})
          super()
          self.merge!(hash)
          self[:status] = :unknown unless hash.has_key?(:status)
        end
        
        def to_hash()
          Hash.new.merge(self)
        end

        def failed?()
          self[:status] == :failed
        end

        def set_status_failed!()
          self[:status] = :failed
        end
        def set_status_succeeded!()
          self[:status] = :succeeded
        end
        def set_status_canceled!()
          self[:status] = :canceled
        end
        def set_dynamic_attributes!(dynamic_attributes)
          self[:dynamic_attributes] = dynamic_attributes
        end
      end
      class ResponseFailed < Response
        def initialize(error,info={})
          super({:status => :failed, :error => error}.merge(info))
        end
      end
      class ResponseSucceeded < Response
        def initialize(info={})
          super({:status => :succeeded}.merge(info))
        end
      end
    end
  end
  class Report
    def self.set_status(status)
      Thread.current[:report_status] = status.to_sym
    end
    def self.get_status()
      Thread.current[:report_status]
    end
    def self.set_report_info(report_info)
      Thread.current[:report_info] = report_info
    end
    def self.get_report_info()
      Thread.current[:report_info]||{}
    end
  end
end

Puppet::Reports.register_report(:r8report) do
  desc "report for R8 agent"

  def process
    MCollective::Report.set_status(status)

    #TODO: right now just passing raw info nack on errors; may normalize here
    report_info = Hash.new
    errors = logs.select{|log_el|log_el.level == :err}
    unless errors.empty?
      report_info[:errors] = errors.map do |err|
        {
          "message" => err.message,
          "source" => err.source,
          "tags" => err.tags,
          "time" => err.time
        }
      end
    end
    MCollective::Report.set_report_info(report_info)
    self
  end
end
