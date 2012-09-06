#!/usr/bin/env ruby
require 'rubygems'
require 'chef'
require 'chef/application/solo'
require 'chef/client'
require 'git'

#TODO: move to be shared by agents
ChefSoloLogDir = "/var/log/chef"
CookbookPath =  "/var/chef/cookbooks"

module MCollective
  module Agent
    class Chef_solo < RPC::Agent
            metadata    :name        => "run chef actions",
                        :description => "Agent to initiate Chef solo runs",
                        :author      => "Reactor8",
                        :license     => "",
                        :version     => "",
                        :url         => "",
                        :timeout     => 300

      def initialize()
        super()
        @log = Log.instance
      end

      def run_action
        validate :run_list, :list
        validate :attributes, :list
        validate :task_id, :string 
        validate :top_task_id, :string
        log_params()

        @msg_id = request.uniqid
        @task_info = [:task_id,:top_task_id].inject({}) do |h,k|
          h.merge(k => request[k])
        end.merge(:msg_id => @msg_id)

        more_generic_response = {:status => :unknown}
        begin
          pull_recipes(request[:run_list])
          run_recipe(request[:run_list],request[:attributes])
        rescue Exception => e
          more_generic_response = {
            :status => :failed, 
            :error => {
              :formatted_exception => e.inspect
            }
          }
        end
        handler_response = RunHandler::Response.delete(request.uniqid)
        reply.data = handler_response || more_generic_response
      end
     private
      def log_params()
        @log.info("params: #{request.data.inspect}")
      end
      def pull_recipes(run_list)
        cookbooks = run_list.map do |el|
          if el =~ /recipe\[(.+)\]/
            recipe = $1
            recipe.gsub(/::.+$/,"") + "/"
          end
        end.compact
        File.open("#{CookbookPath}/.git/info/sparse-checkout","w") do |f|
          f << (cookbooks.join("\n") + "\n")
        end
        g = Git.open(CookbookPath)
        g.checkout
        pull_res = g.pull('origin','origin/master')
      end

      def run_recipe(run_list,attributes)
        chef_client = Chef::Application::Solo.new

        log_file_path = log_file_path()
        log_file = nil
        begin
          log_file = File.open(log_file_path,"a")
          Chef::Config[:log_location] = log_file
          most_recent_link = most_recent_file_path()
          File.delete(most_recent_link) if File.exists? most_recent_link
          File.symlink(log_file_path,most_recent_link)

          #so does not look file json attributes file
          Chef::Config[:json_attribs] = nil

          chef_client.reconfigure
          handler = RunHandler.new(@msg_id,@task_info)
          Chef::Config[:report_handlers] << handler
          Chef::Config[:exception_handlers] << handler
          chef_client.setup_application
          hash_attribs = (attributes||{}).merge({"run_list" => run_list||[]})
          Chef::Client.new(hash_attribs).run
         ensure
          log_file.close
        end

      end
      
      def log_file_path()
        "#{ChefSoloLogDir}/#{id_info()}.log"
      end
      def most_recent_file_path()
        "#{ChefSoloLogDir}/last.log"
      end
      def id_info()
        [:msg_id,:task_id,:top_task_id].map do |k|
          if @task_info.has_key?(k)
            "#{k}:#{@task_info[k].to_s}"
          end
        end.compact.join(":")
      end

      class RunHandler < Chef::Handler
        Response = {}
        def initialize(msg_id,task_info)
          super()
          @msg_id = msg_id
          @task_info = task_info
        end
        def report()
          response = {:node_name => node.name}
          if success?()
            response.merge!(:status => :succeeded)
          else
            error_info = {
              :status => :failed,
              :error => {
                #TODO: log the backtrace, rather than returning it
                #          :backtrace =>  Array(backtrace),
                :formatted_exception => run_status.formatted_exception
              }
            }
            response.merge!(error_info)
            Chef::Log.info("error: #{run_status.formatted_exception}")
            Chef::Log.info("backtrace: \n #{Array(backtrace).map{|l|"   #{l}"}.join("\n")}")
          end
          RunHandler::Response[@msg_id] = response
        end
      end
    end
  end
end


