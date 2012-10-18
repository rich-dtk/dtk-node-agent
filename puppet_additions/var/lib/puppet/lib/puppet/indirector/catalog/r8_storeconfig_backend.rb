require 'puppet/indirector/r8_storeconfig_backend'
require 'puppet/resource/catalog'

class Puppet::Resource::Catalog::R8StoreconfigBackend < Puppet::Indirector::R8StoreconfigBackend
  def find(request)
    require 'pp'
    pp [:in_find]
    nil
  end

  # Save the values from a Facts instance as the facts on a Rails Host instance.
  def save(request)
    require 'pp'
    if catalog = request.instance
      catalog.vertices.each  do |r|
        if r.exported?
          #TODO: think the following is ways to get the higher level component
          component = calling_class_or_def_name(catalog,r)
          rsc_title = r.title
          content = r.to_pson_data_hash
          pp([
              :calling_save,
              {:resource_title => rsc_title, 
                :component => component,
                :content => content
              }])
          p = Thread.current[:exported_resources] ||= Hash.new
          (p[component] ||= Hash.new)[rsc_title] = content 
        end
      end
    end
    catalog
  end

  def calling_class_or_def_name(catalog,resource)
    adjs = catalog.adjacent(resource,:direction => :in)
    unless adjs.size == 1
      raise Puppet::Error, "Unexpected size of adjaceny"
    end
    containing_rsc = adjs.first
    #TODO: make sure works with qualified names
    if containing_rsc.type == "Class"
      containing_rsc.title.downcase
    else
      containing_rsc.type.downcase
    end
  end
end
