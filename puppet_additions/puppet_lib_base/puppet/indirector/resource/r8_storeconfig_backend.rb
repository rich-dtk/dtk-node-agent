require 'puppet/indirector/r8_storeconfig_backend'

class Puppet::Resource::R8StoreconfigBackend < Puppet::Indirector::R8StoreconfigBackend
  def search(request)
    ret = Array.new
    require 'pp' ; pp [:in_search]
    type   = request_to_type_name(request)
    host   = request.options[:host]
    filter = request.options[:filter]
    imp_colls = Thread.current[:imported_collections]
    return ret if imp_colls.nil? or imp_colls.empty?
    imp_colls.each do |cmp,attrs|
      attrs.each do |attr,attr_info|
        next unless attr_info["resource_type"] == type
        ret << R8StoreconfigBackendResource.new(attr_info["value"]) if match(attr_info,filter)
      end
    end
    ret
  end

 private
  def request_to_type_name(request)
    name = request.key.split('/', 2)[0]
    type = Puppet::Type.type(name) or raise Puppet::Error, "Could not find type #{name}"
    type.name.to_s
  end

  def match(attr_info,filter)
    return true if filter.nil? or filter.empty?
    if filter[1] == "=="
      key = filter[0]
      val = filter[2]
      match = ((attr_info["value"]||{})["parameters"]||{}).find{|k,v|k == key}
      match && (match[1] == val)
    else
      raise Puppet::Error, "Do not treat filter operation (#{filter[1]})"
    end
  end
end

class R8StoreconfigBackendResource < Hash
  def initialize(val)
    super()
    val.each{|k,v|self[k]=v}
  end

  def to_resource(scope)
    source = scope.source

    params = self["parameters"].map{|param,val|to_resourceparam(param,val,source) unless val.nil?}.compact

    hash = {
      :scope => scope,
      :source => source,
      :parameters => params
    }
    ret = Puppet::Parser::Resource.new(self["type"],self["title"], hash)
    #TODO: Store the ID, so we can check if we're re-collecting the same resource.
    #ret.collector_id = self.id
    ret
  end
  private
  def to_resourceparam(param,value,source)
    hash = {
      :name => param,
      :value => value,
      :source => source
    }
    Puppet::Parser::Resource::Param.new(hash)
  end
end

