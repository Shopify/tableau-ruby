$:.unshift File.dirname(__FILE__)

require 'nokogiri'
require 'faraday'
require 'faraday_middleware'
require 'oj'

require 'tableau_ruby/util/configuration'

Dir[File.dirname(__FILE__) + '/tableau_ruby/*.rb'].each do |file|
  require file
end


module Tableau
  extend SingleForwardable

  def_delegators :configuration, :host, :admin_name, :admin_password

  ##
  # Pre-configure with credentials so that you don't need to
  # pass them to various initializers each time.
  def self.configure(&block)
    yield configuration
  end

  ##
  # Returns an existing or instantiates a new configuration object.
  def self.configuration
    @configuration ||= Util::Configuration.new
  end
  private_class_method :configuration
end
