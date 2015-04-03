require 'interrobang/version'

# Convert your `#predicate_methods?` to `#bang_methods!`
module Interrobang
  # Exception to raise when no block is provided for bangified falsey methods
  FalsePredicate = Class.new(StandardError)

  # Regexp that matches methods that end in question marks.
  DEFAULT_PATTERN = %r{\A[^?]+\?\z}

  module_function

  # Wrapper method for `bangify_class` and `bangify_method`. The appropriate
  # method will be called depending on the method signature.
  #
  # Examples
  #
  #     Interrobang.bangify(Answer) # => [:correct!]
  #     Interrobang.bangify(Answer, :is_correct) # => :is_correct!
  #
  # Returns either a Symbol or Symbol Array of bangified method names.
  def bangify(*args, **keywords, &block)
    klass, method = args
    if method
      bangify_method(klass, method, **keywords, &block)
    else
      bangify_class(klass, **keywords, &block)
    end
  end

  # Converts the specified predicate methods in a class to bang methods.
  #
  # klass - The Class to target for bangification
  # block - An optional block to run if a predicate method returns something falsey
  #
  # Options
  #
  #   matching - The Regexp used to match methods that should be bangified; defaults to DEFAULT_PATTERN
  #   only - The Symbol or Symbol Array of methods to bangify exclusively
  #   except - The Symbol or Symbol Array of methods to ignore when pattern matching
  #   prefix - The String prefix to add to front of the bangified method
  #   suffix - The String suffix to add to end of the bangified method
  #   inlcude_super - The Boolean specifying whether to bangify parent methods
  #
  # Returns the Symbol Array of bangified method names.
  def bangify_class(klass, matching: DEFAULT_PATTERN, only: [], except: [], prefix: '', suffix: '', include_super: false, &block)
    method_keys = klass.instance_methods(include_super)
    only = [only] unless only.is_a?(Array)
    except = [except] unless except.is_a?(Array)
    methods_to_bangify =
      if only.empty?
        (method_keys - except).select { |method_key| method_key.to_s =~ matching }
      else
        method_keys & only
      end
    methods_to_bangify.map do |method_key|
      bangify_method(klass, method_key, prefix: prefix, suffix: suffix, &block)
    end
  end

  # Converts the specified predicate method to a bang method. Beware: bang
  # methods will be created for undefined methods too.
  #
  # klass - The Class to target for bangification
  # predicate_method - The Symbol of the predicate method
  # block - An optional block to run if a predicate method returns something falsey
  #
  # Options
  #
  #   matching - The Regexp used to match methods that should be bangified
  #   prefix - The String prefix to add to front of the bangified method
  #   suffix - The String suffix to add to end of the bangified method
  #
  # Returns the Symbol name of the bang method created.
  def bangify_method(klass, predicate_method, prefix: '', suffix: '')
    predicate_method_string = predicate_method.to_s
    method_name_base =
      case predicate_method_string[-1]
      when '=', '!'
        return
      when '?'
        predicate_method.to_s[0..-2]
      else
        predicate_method.to_s
      end

    bang_method = :"#{prefix}#{method_name_base}#{suffix}!"

    klass.class_eval do
      if block_given?
        define_method(bang_method) do |*args, &block|
          if send(predicate_method, *args, &block)
            true
          else
            yield(predicate_method)
          end
        end
      else
        define_method(bang_method) do |*args, &block|
          if send(predicate_method, *args, &block)
            true
          else
            raise(Interrobang::FalsePredicate, "#{predicate_method} is false")
          end
        end
      end
    end
    bang_method
  end
end

# Alias for `Interrobang.bangify`
def Interrobang(*args, &block)
  Interrobang.bangify(*args, &block)
end