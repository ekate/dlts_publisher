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
end