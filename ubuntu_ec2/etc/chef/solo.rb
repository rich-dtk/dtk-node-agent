file_cache_path "/var/chef/cache"
cookbook_path "/var/chef/cookbooks"
#json_attribs "/etc/chef/node.json"
#log_location "/var/chef/solo.log"
verbose_logging true
log_level :debug
require "/var/chef/handlers/simple_handler"
handler = SimpleRunHandler.new
report_handlers << handler
exception_handlers << handler
