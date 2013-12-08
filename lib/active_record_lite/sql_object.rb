require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  
  extend Searchable
  extend Associatable
  
  # sets the table_name
  def self.set_table_name(table_name = self.to_s.tableize)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    
    rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL
    
    rows.map { |row| self.new(row) }
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    row = DBConnection.execute(<<-SQL, :id => id).first
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = :id
      SQL
    
    self.new(row) if row        
  end

  # call either create or update depending if id is nil.
  def save
    self.id.nil? ? create : update
  end


  private
  
  # helper method to return values of the attributes.
  def attribute_values
    # how/why would you use `send` instead of `instance_variable_get`?
    self.class.attributes.each_with_object([]) do |attr_name, values|
      next if attr_name == :id
      values << instance_variable_get(ivar_name(attr_name))
    end
  end
  
  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
    columns = []
    
    self.class.attributes.each do |attr_name|
      next if attr_name == :id
      columns << attr_name.to_s
    end
    
    question_marks = (["?"] * columns.count).join(", ")
       
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{columns.join(", ")})
      VALUES
        (#{question_marks})
      SQL
      
    @id = DBConnection.last_insert_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    set_strings = []
    
    self.class.attributes.each do |attr_name|
      next if attr_name == :id
      set_strings << "#{attr_name} = ?"
    end
    
    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_strings.join(", ")}
      WHERE
        id = #{self.id}
      SQL
  
  end
end
