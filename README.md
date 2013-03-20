dtk-node-agent
==============

Code that is present in AMIs that server basis for nodes being spun up

### Intalling the node agent on an existing AMI
`sudo ./install_agent.sh`

### Install the agent and create a new AMI image
`ruby create_agent_ami.rb region ami_id key_name key_path ssh_username image_name`

example:  
`ruby create_agent_ami.rb us-east-1 ami-da0000aa test_key /somepath/test_key.pem root r8-agent-ubuntu-precise`



