require 'ewallet/config'
require 'ewallet/client'
require 'ewallet/api'

module Ewallet
  extend Ewallet::Client
  extend Ewallet::Api

  class << self
    def config(&block)
      if block
        instance_eval(&block)
      else
        Ewallet::Config
      end
    end
    alias_method :setup, :config

  end
end
