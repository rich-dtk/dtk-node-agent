#!/usr/bin/env ruby
require 'rubygems'
require 'chef'
require 'chef/application/solo'
require 'chef/client'
require 'git'

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
        #TODO validate :task_id and :top_task_id
        more_generic_response = {:status => :unknown}
        begin
          pull_recipes(request.uniqid,request[:run_list])
          task_info = [:task_id,:top_task_id].inject({}) do |h,k|
            request[k] ? h.merge(k => request[k]) : h
          end
          run_recipe(request.uniqid,request[:run_list],request[:attributes],task_info)
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
      def pull_recipes(id,run_list)
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
        pp [:pull,pull_res]
      end

      def run_recipe(id,run_list,attributes,task_info)
        @log.info("run_list: #{run_list.inspect}")
        @log.info("attributes: #{attributes.inspect}")
        chef_client = Chef::Application::Solo.new
        chef_client.reconfigure
        handler = RunHandler.new(id,task_info)
        Chef::Config[:report_handlers] << handler
        Chef::Config[:exception_handlers] << handler
        chef_client.setup_application
        hash_attribs = (attributes||{}).merge({"run_list" => run_list||[]})
        Chef::Client.new(hash_attribs).run
      end

      class RunHandler < Chef::Handler
        Response = {}
        def initialize(msg_id,task_info)
          super()
          @msg_id = msg_id
          @task_info = task_info.merge(:msg_id => @msg_id)
          mark_activity_start()
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
          mark_activity_end()
          RunHandler::Response[@msg_id] = response
        end
       private
        def mark_activity_start()
          Chef::Log.info("START_MARKER: #{id_info}")
        end
        def mark_activity_end()
          Chef::Log.info("END_MARKER: #{id_info}")
        end
        def id_info()
          [:msg_id,:task_id,:top_task_id].map do |k|
            if @task_info.has_key?(k)
              "#{k}:#{@task_info[k].to_s}|"
            end
          end.compact.join(" ")
        end
      end
    end
  end
end

