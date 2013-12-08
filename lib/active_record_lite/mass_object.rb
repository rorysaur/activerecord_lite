class MassObject
  
  # takes a list of attributes.
  # adds attributes to whitelist.
  def self.my_attr_accessible(*attributes)
    attributes.each do |attribute|
      self.attributes << attribute
    end
  end

  # takes a list of attributes.
  # makes getters and setters
  def self.my_attr_accessor(*attributes)
    attributes.each do |attribute|
      ivar_name = "@" + attribute.to_s
      setter_name = attribute.to_s + "="

      define_method(attribute) do
        instance_variable_get(ivar_name)
      end
      
      define_method(setter_name) do |value|
        instance_variable_set(ivar_name, value)
      end
    end
  end


  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes ||= []
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    results.map { |params| self.new(params) }
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})
    params.each do |attr_name, attr_val|
      attr_name = attr_name.to_sym if attr_name.is_a?(String)
      
      if !self.class.attributes.include?(attr_name)
        raise "mass assignment to unregistered attribute #{attr_name}"
      else
        instance_variable_set(ivar_name(attr_name), attr_val)
      end
    end
  end
  
  def ivar_name(attr_name)
    "@" + attr_name.to_s
  end
  
end




