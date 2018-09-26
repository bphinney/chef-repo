# Logging module

require 'logger'

# Module constructs a configurable and expandable logger
#
# Use:
# include Logging
# log_header = 'A Custom Log Header'    # Defaults to ''
# log_level  = 'warn'                   # Defaults to Logger::INFO
# log_file   = 'yourlog.log'            # Can be relative, defaults to STDOUT
# 
# Logging.config(log_header, log_level, log_file) # load custom options
# OR
# Logging.config() # Loads just the defaults
#
# log.debug("You are now ready to log")
#

module Logging

  # MultiDelegator will split writes to multiple objects
  # Used to write to both STDOUT and log file simultaneously 
  class MultiDelegator
    def initialize(*targets)
      @targets = targets
    end

    def self.delegate(*methods)
      methods.each do |m|
        define_method(m) do |*args|
          @targets.map { |t| t.send(m, *args) }
        end
      end
      self
    end

    class <<self
      alias to new
    end
  end

  # Configuration defaults
  def self.config(log_header='', log_level='info', log_file='')

    level = case log_level
    when 'debug'
      Logger::DEBUG
    when 'info'
     Logger::INFO
    when 'warn'
      Logger::WARN
    when 'error'
      Logger::ERROR
    when 'fatal'
      Logger::FATAL
    when 'unknown'
      Logger::UNKNOWN
    end

    @log_header = log_header
    @log_level  = level
    @stdout     = STDOUT

    if log_file.empty?
      @file = ''
    else
      @file = File.open(log_file, File::WRONLY | File::APPEND | File::CREAT )
    end

    # Formatting for the logline
    @formatter  = proc do |severity, datetime, progname, msg|
      #"[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] - #{severity} - #{msg}\n"
      "#{@log_header} #{severity} - #{msg}\n"
    end

    # Run formatter
    formatter
  end
 
  # Method is a formatter entrypoint
  def formatter
    logger.formatter = @formatter
    logger.level = @log_level
  end
 
  # Method is syntactic sugar to shorten log initialization  
  def logger
    Logging.logger
  end

  # Method initates lazy, memoized logger
  def self.logger
    if @file == ''
      @logger ||= Logger.new(@stdout)
    else
      # Log to stdout and file
      @logger ||= Logger.new MultiDelegator.delegate(:write, :close).to(@stdout, @file)
    end
  end
end

