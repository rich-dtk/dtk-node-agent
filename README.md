dtk-node-agent
==============

Code that is present in AMIs that server basis for nodes being spun up

### Intalling the node agent on an existing AMI
`sudo ./install_agent.sh`

### Install the agent and create a new AMI image
```
ruby create_agent_ami.rb --help    
Options:
          --region, -r <s>:   AWS Region on which to create the AMI image
         --aws-key, -a <s>:   AWS Access Key
      --aws-secret, -w <s>:   AWS Secret Access Key
  --security-group, -s <s>:   AWS Security group (default: default)
        --key-pair, -k <s>:   AWS keypair for the new instance
        --key-path, -e <s>:   Path to the PEM file for ssh access
    --ssh-username, -u <s>:   SSH Username
          --ami-id, -m <s>:   AMI id which to spin up
      --image-name, -i <s>:   Name of the new image
                --help, -h:   Show this message
```

example:  
```
ruby create_agent_ami.rb --region us-east-1 --ami-id ami-da0000aa --key-pair test_key --key-path /somepath/test_key.pem \
--ssh-username root --image-name r8-agent-ubuntu-precise
```
 


