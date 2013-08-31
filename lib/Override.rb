require "Override/version"
require "Override/override_method"
require "Override/override_any"
require "Override/exception"


##
# `Override` module provides functional for creating methods 
# with types in Ruby.
#
#
# == Usage
#   
# Firstly include `Override` in you class
#  
#   class MyClass        
#     include Override 
#   end
#
# After define method with types:
#   
#   class MyClass
#     include Override   
#     
#     # with Fixnum type 
#     let :cool_method, Fixnum do |num|
#       num * 100
#     end 
#     
#     # with String type
#     let :cool_method, String do |str|
#       str << "!"
#     end 
#   end
#   
# And now
#      
#   my_class = MyClass.new
#   my_class.cool_method(3)     # => 300
#   my_class.cool_method("foo") # => foo!  
#
#
# == Initialize Method
# 
# For define overloaded `initialize` method use `this`
#   
#   class MyClass
#     include Override  
#     attr_accessor :arg     
#     undef :initialize #remove own method
#     let :this, Fixnum do |arg|
#       @arg = arg
#     end
#     let :this, String do |arg|
#       @arg = arg
#     end
#   end
#   
#   my_class = MyClass.new(1)     # => @arg == 1
#   my_class = MyClass.new("foo") # => @arg == "foo"     
#  
# == Any Type
#  
#   class MyClass 
#     include Override
#     let :cool_method, Any do |any|
#       any
#     end 
#   end
#   
#   my_class = MyClass.new
#   my_class.cool_method(1)     # => 1 
#   my_class.cool_method("foo") # => "foo"
#
# Is the same so ruby `def` 
#
#
module Override
  def self.included(base) # :nodoc:
    base.extend(self)
    base.class_eval do 
      class_variable_set(:@@__overridable_methods, [])
    end
  end

  def __overridable_methods # :nodoc:
    class_variable_get(:@@__overridable_methods)
  end

  ##
  # Create new method with +name+ and +types+
  # When method called +block+ will be executed
  #
  # +name+ is symbol
  #
  # +types+ types for method
  #
  def let(name, *types, &block)
    __overridable_methods << OverrideMethod.new(name, types, self, block)
    
    if !self.method_defined?(name)
      self.instance_exec do
        self.send(:define_method, name) do |*args, &block|
          types = *args.map(&:class)
          owner = self.class
          
          compare = lambda do |a, b| 
            return false if a.size != b.size
            !a.zip(b).map do |arr| 
              first, last = arr 
              true if (first == Override::Any) || (last == Override::Any) || (first == last)  
            end.include?(nil)
          end
          
          #find all ancestors which have our method
          methods = owner.ancestors.find_all do |ancestor| 
            if name != :initialize
              ancestor.method_defined?(name) && ancestor.class == Class
            else 
              true if ancestor.method_defined?(:__overridable_methods) && ancestor.class == Class
            end
          end.map do |ancestor| 
            ancestor.__overridable_methods.find_all {|m| m.name == name }
          end.flatten.find_all do |method|
            compare[method.types, types]
          end.uniq

          z = methods.find{|_| _.owner == owner} || methods.first

          raise NotImplementError.new("Method `#{name}` in `#{self}` class with types `#{types}` not implemented.") if z.nil?
          _block = z.body
          instance_exec(*args, &_block)
        end
      end
    end   
  end

  def method_missing(method, *args, &block) # :nodoc:
=begin    
    types = *args.map(&:class)
    method = :this if method == :initialize
    
    #first find in class
    #after in parent class
    owner, parent = self.class, self.class.superclass

    _ms = owner.__overridable_methods
             .find_all{|_| _.name == method}
    
    compare = lambda do |a, b| 
      return false if a.size != b.size
      !a.zip(b).map do |arr| 
        first, last = arr 
        true if (first == Override::Any) || (last == Override::Any) || (first == last)  
      end.include?(nil)
    end  
    
    z = _ms.find{|_| compare[_.types, types] and _.owner == owner} ||
        _ms.find{|_| compare[_.types, types] and _.owner == parent} 

        
    raise NotImplementError.new("Method `#{method}` in `#{owner}` class with types `#{types}` not implemented.") if z.nil?

    _block = z.body
    instance_exec(*args, &_block)
=end 
  end
 
end



