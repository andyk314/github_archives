require 'open-uri'
require 'pry'
require 'date'
# Suggested JSON parsing library from https://www.githubarchive.org/
require 'zlib'
require 'yajl'

# help = "[--after DATETIME] [--before DATETIME] [--event EVENT_NAME] [-n COUNT]"
# puts help if ARGV.empty?

# Sample Script to be Run
# ruby github.rb 2012-11-01T13:00:00Z 2012-11-02T03:12:14-03:00 PushEvent 42

start = Time.parse(ARGV[0])
stop = Time.parse(ARGV[1])
$TYPE = ARGV[2]
$COUNT = ARGV[3].to_i

$events = Hash.new(0) #Keep track of filtered events and frequency

# generate url based on time
def generate_url(time)
  "http://data.githubarchive.org/#{time}.json.gz"
end

# generate connection to file/url
def conn(url)
  gz = open(url)
  Zlib::GzipReader.new(gz).read
end

# Parse through data/file. Filters out particular event type and save repository name and frequency to $events hash
def parser(js)
  Yajl::Parser.parse(js) do |event|
    if event['type'] == $TYPE
      if event['repository']
        repo_name = event['repository']['url'].gsub('https://github.com/', '')
        $events[repo_name] +=1
      elsif event['repo'] #to account for older api that uses 'repo' instead of 'repository'
        repo_name = event['repo']['url'].gsub('https://github.com/', '')
        $events[repo_name] +=1
      end
    end
  end
end

# Iterate through a given range of time
time = start
while time < stop
  formatted_time = time.strftime('%Y-%m-%d-%H')
  url = generate_url(formatted_time)
  js = conn(url)
  parser(js)
  time += 3600
end

# Sort events based on # of events and return top repos
sorted_events = $events.sort_by {|_key, value| value}.reverse.first($COUNT)

sorted_events.each { |e| puts "#{e[0]} - #{e[1]} events" }
