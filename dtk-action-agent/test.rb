require 'json'
require 'ap'

test_array =
  {
    :commands => ["date","more /var/log/mcollective.log"]
  }


transform_to_string = test_array.to_json

# we need to escape '/' due to system calls
#transform_to_string.gsub!('/',"\\/")

# DEBUG SNIPPET >>> REMOVE <<<
require 'ap'
ap transform_to_string
#ap "dtk-action-agent \"#{transform_to_string}\""
result =  `dtk-action-agent '#{transform_to_string}'`

ap result


