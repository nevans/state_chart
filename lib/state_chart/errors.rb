# frozen_string_literal: true

require_relative "errors"

module StateChart

  class Error < StandardError; end

  class InvalidName < Error; end

  class InvalidReference < Error; end

end
