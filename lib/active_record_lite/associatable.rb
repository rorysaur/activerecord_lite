require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table_name
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  
  attr_accessor :other_class_name, :primary_key, :foreign_key
    
  def initialize(assoc_name, params, self_class)
    default_params = {
      :class_name => "#{assoc_name.to_s.camelize}",
      :foreign_key => assoc_name.to_s.foreign_key.to_sym,
      :primary_key => :id
    }
    
    params = default_params.merge(params)
    
    @other_class_name = params[:class_name]
    @primary_key = params[:primary_key]
    @foreign_key = params[:foreign_key]
    
    self_class.assoc_params[assoc_name] = self
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  
  attr_accessor :other_class_name, :primary_key, :foreign_key
  
  def initialize(assoc_name, params, self_class)
    default_params = {
      :class_name => "#{assoc_name.to_s.classify}",
      :foreign_key => self_class.to_s.foreign_key.to_sym,
      :primary_key => :id
    }
    
    params = default_params.merge(params)
        
    @other_class_name = params[:class_name]
    @primary_key = params[:primary_key]
    @foreign_key = params[:foreign_key]
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(assoc_name, params = {})
    assoc_params = BelongsToAssocParams.new(assoc_name, params, self)
    
    define_method(assoc_name) do
      
      f_key = assoc_params.foreign_key
      other_table = assoc_params.other_table_name
      p_key = assoc_params.primary_key
                  
      row = DBConnection.execute(<<-SQL).first
        SELECT
          *
        FROM
          #{other_table}
        WHERE
          #{p_key} = #{self.send(f_key)}
        SQL
              
      assoc_params.other_class.new(row)
    end
  end

  def has_many(assoc_name, params = {})
    assoc_params = HasManyAssocParams.new(assoc_name, params, self)
    
    define_method(assoc_name) do
      
      f_key = assoc_params.foreign_key
      other_table = assoc_params.other_table_name
      p_key = assoc_params.primary_key
      
      rows = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{other_table}
        WHERE
          #{f_key} = #{self.send(p_key)}
        SQL
      
      rows.map { |row| assoc_params.other_class.new(row) }
    end
  end

  def has_one_through(assoc_name, assoc1, assoc2)
    
    define_method(assoc_name) do
      
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]
      
      f_key1 = params1.foreign_key
      join_table = params1.other_table_name
      p_key1 = params1.primary_key
      
      f_key2 = params2.foreign_key
      final_table = params2.other_table_name
      p_key2 = params2.primary_key
      
      row = DBConnection.execute(<<-SQL).first
        SELECT
          #{final_table}.*
        FROM
          #{final_table}
        JOIN
          #{join_table}
        ON
          #{final_table}.#{p_key2} = #{join_table}.#{f_key2}
        WHERE
          #{join_table}.#{p_key1} = #{self.send(f_key1)}
        SQL

      params2.other_class.new(row)
    end
  end
  
end





