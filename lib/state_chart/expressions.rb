# frozen_string_literal: true

require_relative "errors"
require_relative "util"

module StateChart

  module Expressions

    class Condition

      def initialize(**opts)
        @cond = validate_cond_format(**opts)
      end

      attr_reader :cond

      def unconditional?; @cond.nil? || @cond == true end
      def conditional?; !unconditional? end

      alias cond? conditional?

      # TODO
      def evaluate?
        raise NotImplementedError
      end

      private

      def validate_cond_format(**opts)
        cond = merge_cond_opts(**opts)
        case cond
        when nil, true; true
        when false;     false
        when Proc;      cond
        when String;   -cond # TODO: parse it to ensure it's valid ruby
        when Util::Regex::VALID_PREDICATE_NAME; cond
        when Hash
          key, val = cond.first
          if cond.size == 1 && key == :not
            {not: validate_cond_format(val)}
          else
            raise Error, "invalid cond format: %p" % [cond]
          end
        else
          if cond.respond_to?(:call)
            cond
          else
            raise Error, "invalid cond format: %p" % [cond]
          end
        end
      end

      def merge_cond_opts(**opts)
        validate_cond_kwargs(**opts)
        case opts.length
        when 0; true
        when 1
          key, val = opts.first
          (key == :if) ? val : {not: val}
        else raise Error, "Must only send one of %p", [opts]
        end
      end

      def validate_cond_kwargs(if: nil, unless: nil)
        # we can't use if and unless directly from keyword args, because they are
        # ruby keywords themselves. so we need to pull them off of **opts.
        # This just ensures that only valid cond opts were sent to the caller.
      end

    end

  end
end
