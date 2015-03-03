require 'predicate_bang/version'

# Convert your `#predicate_methods?` to `#bang_methods!`
module PredicateBang
  # Exception to raise when no block is provided for bangified falsey methods
  FalsePredicate = Class.new(Exception)

  # Regexp that matches methods that end in question marks.
  DEFAULT_PATTERN = %r{\A[^?]+\?\z}

  module_function

  # Converts the specified predicate methods in a class to to bang methods
  #
  # klass - The Class to target for bangification
  # block - An optional block to run if a predicate method returns something falsey
  #
  # Options
  #
  #   matching - The Regexp used to match methods that should be bangified
  #   only - The Symbol Array of methods to bangify exclusively
  #   except - The Symbol Array of methods to bangify ignore when pattern matching
  #   prefix - The String prefix to add to front of the bangified method
  #   suffix - The String suffix to add to end of the bangified method
  #   inlcude_super - The Boolean specifying whether to bangify parent methods
  #
  # Returns nothing.
  def bangify(klass, matching: DEFAULT_PATTERN, only: [], except: [], prefix: '', suffix: '', include_super: false)
    method_keys = klass.instance_methods(include_super)
    if only.empty?
      method_keys.each do |method_key|
        if method_key.to_s =~ matching && !except.include?(method_key)
          if block_given?
            bangify_method(klass, method_key, prefix: prefix, suffix: suffix, &Proc.new)
          else
            bangify_method(klass, method_key, prefix: prefix, suffix: suffix)
          end
        end
      end
    else
      method_keys.each do |method_key|
        if only.include?(method_key)
          if block_given?
            bangify_method(klass, method_key, prefix: prefix, suffix: suffix, &Proc.new)
          else
            bangify_method(klass, method_key, prefix: prefix, suffix: suffix)
          end
        end
      end
    end
  end

  # Converts the specified predicate method to a bang method
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
  # Returns nothing.
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
            raise(PredicateBang::FalsePredicate, "#{predicate_method} is false")
          end
        end
      end
    end
  end

end
