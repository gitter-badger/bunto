require 'fileutils'
require 'posix-spawn'
require 'minitest/assertions'
require 'time'

BUNTO_SOURCE_DIR = File.dirname(File.dirname(File.dirname(__FILE__)))
TEST_DIR    = File.expand_path(File.join('..', '..', 'tmp', 'bunto'), File.dirname(__FILE__))
BUNTO_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'bunto'))
BUNTO_COMMAND_OUTPUT_FILE = File.join(File.dirname(TEST_DIR), 'bunto_output.txt')

def source_dir(*files)
  File.join(TEST_DIR, *files)
end

def all_steps_to_path(path)
  source = Pathname.new(source_dir('_site')).expand_path
  dest   = Pathname.new(path).expand_path
  paths  = []
  dest.ascend do |f|
    break if f.eql? source
    paths.unshift f.to_s
  end
  paths
end

def bunto_output_file
  BUNTO_COMMAND_OUTPUT_FILE
end

def bunto_run_output
  File.read(bunto_output_file) if File.file?(bunto_output_file)
end

def run_bundle(args)
  child = run_in_shell('bundle', *args.strip.split(' '))
end

def run_bunto(args)
  child = run_in_shell(BUNTO_PATH, *args.strip.split(' '), "--trace")
  child.status.exitstatus == 0
end

def run_in_shell(*args)
  POSIX::Spawn::Child.new *args, :out => [BUNTO_COMMAND_OUTPUT_FILE, "w"]
end

def slug(title)
  if title
    title.downcase.gsub(/[^\w]/, " ").strip.gsub(/\s+/, '-')
  else
    Time.now.strftime("%s%9N") # nanoseconds since the Epoch
  end
end

def location(folder, direction)
  if folder
    before = folder if direction == "in"
    after = folder if direction == "under"
  end
  [before || '.', after || '.']
end

def file_contents(path)
  File.open(path) do |file|
    file.readlines.join # avoid differences with \n and \r\n line endings
  end
end

def seconds_agnostic_datetime(datetime = Time.now)
  date, time, zone = datetime.to_s.split(" ")
  time = seconds_agnostic_time(time)
  [
    Regexp.escape(date),
    "#{time}:\\d{2}",
    Regexp.escape(zone)
  ].join("\\ ")
end

def seconds_agnostic_time(time)
  if time.is_a? Time
    time = time.strftime("%H:%M:%S")
  end
  hour, minutes, _ = time.split(":")
  "#{hour}:#{minutes}"
end
