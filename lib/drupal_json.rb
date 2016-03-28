require 'json'
class DrupalJson
  def drupal_field(label,value,field_type, machine_name)
  { :label=> "#{label}", :value => ["#{value}"], :field_type =>"#{field_type}",
                          :machine_name=>"#{machine_name}" }
  end
  def drupal_field_array(label,value,field_type, machine_name)
    { :label=> "#{label}", :value => value, :field_type =>"#{field_type}",
      :machine_name=>"#{machine_name}" }
  end
  def drupal_collection_array(collections)
     collections_array=[]
     collections.each do |collection| 
    collections_array<<{ :label=> "Collection", :value => collection, :field_type =>"node_reference_autocomplete",
      :machine_name=>"collection_field" }
     end
     return collections_array
  end
end
