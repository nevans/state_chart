# frozen_string_literal: true

module StateChart

  # adapted from Aaron Patterson's version of visitor pattern (arel and journey)
  class Visitor

    def self.dispatch_cache
      @dispatch_cache ||= Hash.new do |hash, klass|
        hash[klass] = -"visit_#{(klass.name || '').gsub('::', '_')}"
      end
    end

    def initialize
      @dispatch = self.class.dispatch_cache
    end

    attr_reader :dispatch

    def visit(object, *a, **kw, &b)
      method = dispatch[object.class]
      send method, object, *a, **kw, &b
    rescue NoMethodError => e
      raise e if respond_to?(method, true)
      superclass = object.class.ancestors.find {|klass|
        respond_to?(dispatch[klass], true)
      }
      raise(TypeError, "Cannot visit #{object.class}") unless superclass
      dispatch[object.class] = dispatch[superclass] # update cache
      retry
    end

  end

end
