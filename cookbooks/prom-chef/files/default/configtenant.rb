# Class contains method used to initialize conf settings
# This is not to be confused with Gem::ConfigFile, not related

class ConfigFile
  def initialize(c)
    @def_config = c
  end

  # Method overrides default values with associated config file values
  def configure(config)
    config.each { |k, v| @def_config[k] = v if @def_config.include? k }
    return @def_config
  end

  # Load configuration file
  def config_location(config_path)
    begin
      path_file = YAML.load(IO.read(config_path))
      puts "Using config file"
      puts "#{path_file}"
    rescue Errno::ENOENT
      puts 'Config file not found, using defaults'
      return @def_config
    rescue Psych::SyntaxError
      puts 'Config file syntax failure, using defaults'
      return @def_config
    end
    configure(path_file)
  end
end
