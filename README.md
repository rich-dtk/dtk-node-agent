dtk-node-agent
==============

Code that is present in AMIs that server basis for nodes being spun up

### Build the gem:
`gem build dtk-node-agent.gemspec`

#### Intalling the node agent on a running machine (without puppet omnibus)
`sudo dtk-node-agent`

#### Intalling the node agent on a running machine (with puppet omnibus)
`sudo ./install_agent.sh [--sanitize]`

#### Build all supported AMI images with [packer](http://www.packer.io/) 
```
export AWS_ACCESS_KEY="your aws access key"
export AWS_SECRET_KEY="your aws secret key"

packer build template.json
```  
This will also copy images to all AWS regions.  

To get json output of new images, first, add .fog file on your home directory (with valid aws credentials) and then run following ruby script:
```
ruby get_amis.rb <AMI_TIMESTAMPS>
```
AMI_TIMESTAMPS can be one timestamp or array of timestamps separated with delimiter (,)

License
----------------------
DTK Node Agent is released under the GPLv3 license. Please see LICENSE for more details.


