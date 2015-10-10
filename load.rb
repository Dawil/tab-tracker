require 'pry'
require 'yaml'
require 'optparse'

###
# I think a modular output style would make writing code easer.
# Select mode: output as yaml source data from indexes
# Filter mode: filter raw yaml from stdin
# Render mode: print the selected attributes
#
# and use unix pipes to combine them.
#
# E.g.:
#   select:
#     * tabs
#     * thoughts
#     * tabs by thoughts
#     * thoughts by tabs
#   filter by:
#     * date
#     * status
#     * tags
#   render:
#     * url
#     * title
#     * tags
#     * pretty print full info

options = {
  directory: Dir.pwd,
  output: []
}
OptionParser.new do |opts|
  opts.on('-d', '--directory directory', 'Directory') do |directory|
    directory = '/' + directory if directory[0] != '/'
    options[:directory] = Dir.pwd + directory
  end
  opts.on('-l', '--list thing', 'Thing') do |thing|
    options[:list] = thing.to_sym
  end
  opts.on('--thought thought', 'Thought') do |thought|
    options[:thought] = thought
  end
  opts.on('-o', '--output flag', 'Output') do |output|
    options[:output] << output
  end
end.parse!

def main opts
  if thing = opts[:list]
    case thing
    when :unread
      list_unread opts
    when :thoughts
      list_thoughts opts
    end
  else
    puts opts
  end
end

def tabs opts
  Dir[File.join opts[:directory], 'tabs/*/*/*']
end
def thoughts opts
  Dir[File.join opts[:directory], 'thoughts/**/*.thought']
end

def list_unread opts
  tabs(opts).each do |filename|
    f = YAML.load_file filename
    f.each_pair do |index, tab|
      puts "#{filename}/#{index}: #{tab['url']}" unless %w(wont-read have-read).include? tab['status']
    end
  end
end

def output_tabs tabs, opts
  puts 'hi'
  if opts[:output].any? { |flag| flag.include? 'tags' }
    pry
  end
  if opts[:output].include? 'as_yaml'
    puts tabs.to_yaml
  else
    puts tabs.inspect
  end
end

def list_tabs_in_thought opts
  thought = thoughts(opts).find do |thought|
    thought.include? "#{opts[:thought]}.thought" 
  end
  puts thought
  thought_yaml = YAML.load_file thought
  # read tabs to fetch
  tabs_to_fetch = []
  thought_yaml['tabs'].each_pair do |year, year_body|
    year_body.each_pair do |month, month_body|
      month_body.each_pair do |day, day_body|
        path = "#{year}/#{"%02d" % month.to_i}/#{"%02d" % day.to_i}.tabs"
        tabs_to_fetch << [File.join( opts[:directory], 'tabs', path ),
                          day_body]
      end
    end
  end
  # fetch tabs
  selected_tabs = []
  tabs_to_fetch.each do |tab|
    tab_file = YAML.load_file tab[0]
    more_tabs = tab_file.find_all do |key, val|
      tab[1].include? key
    end
    selected_tabs += more_tabs
  end
  puts 'hi'
  output_tabs selected_tabs.map(&:last), opts
end

def list_thoughts opts
  if opts[:thought]
    list_tabs_in_thought opts
  else
    puts thoughts(opts)
  end
end

main options
