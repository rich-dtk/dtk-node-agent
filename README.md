dtk-node-agent
==============

Code that is present in AMIs that server basis for nodes being spun up

### Build the gem:
`gem build dtk-node-agent.gemspec`

#### Intalling the node agent on a running machine (without puppet omnibus)
`sudo dtk-node-agent`

#### Intalling the node agent on a running machine (with puppet omnibus)
`sudo ./install_agent.sh [--sanitize]`

#### Create a new AMI image with the node agent
```
./create_agent_ami.rb --help
Options:
          --region, -r <s>:   AWS Region on which to create the AMI image
         --aws-key, -a <s>:   AWS Access Key
      --aws-secret, -w <s>:   AWS Secret Access Key
  --security-group, -s <s>:   AWS Security group (default: default)
        --key-pair, -k <s>:   AWS keypair for the new instance
        --key-path, -e <s>:   Path to the PEM file for ssh access
    --ssh-username, -u <s>:   SSH Username
     --ssh-timeout, -t <i>:   Time to wait before instance is ssh ready (seconds) (default: 100)
          --ami-id, -m <s>:   AMI id which to spin up
      --image-name, -i <s>:   Name of the new image
                --help, -h:   Show this message
```

example:  
```
ruby create_agent_ami.rb --region us-east-1 --ami-id ami-da0000aa --key-pair test_key --key-path /somepath/test_key.pem \
--ssh-username root --image-name dtk-agent-ubuntu-precise
```

#### Build all supported AMI images with [packer](http://www.packer.io/) 
```
export AWS_ACCESS_KEY="your aws access key"
export AWS_SECRET_KEY="your aws secret key"

packer build template.json
```  
This will also copy images to all AWS regions.  

License
----------------------
DTK Node Agent is released under the GPLv3 license. Please see LICENSE for more details.


