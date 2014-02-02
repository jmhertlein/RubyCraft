#!/usr/bin/env ruby

# Copyright (C) 2013 Joshua Michael Hertlein <jmhertlein@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'optparse'
require 'ostruct'

USAGE = "Usage: rc [OPTIONS] [serverdir]"

def parseOptions(args)
  options = OpenStruct.new
  options.verbose = false
  options.start = false
  options.backup = false
  opt_parser = OptionParser.new do |opts|
    opts.banner = USAGE
    
    opts.on("-v", "--verbose", "Display verbose output.") do |v|
      options.verbose = v
    end

    opts.on("-s", "--start", "Start the server.") do |s|
      options.start = s
    end

    opts.on("-b", "--backup", "Backup the server") do |b|
      options.backup = b
    end

    opts.on("-p", "--persistent", "When starting a server, wait for it to stop then restart.") do |p|
      options.persistent = p
    end
  end.parse!
    
  return options
end

OPTIONS = parseOptions(ARGV)

def output(msg)
  if(OPTIONS.verbose)
    puts msg
  end
end

if (ARGV.size < 1)
  puts "Error: Missing server dir."
  puts USAGE
  exit
elsif (ARGV.size > 1)
  puts "Too many arguments."
  puts USAGE.
  exit
end

SERVER_DIR = ARGV[0]
output "Server Directory: #{SERVER_DIR}"
output "Options: #{OPTIONS}"

if(!OPTIONS.start && !OPTIONS.backup) 
  puts "No actions specified, nothing to do."
  exit
end

if(OPTIONS.backup)
  output "Backing up..."
end

if(OPTIONS.start)
  output "Starting..."
  Dir.chdir(SERVER_DIR)
  while (true) 
    pid = fork do
      `screen -d -m -S mc java -jar craftbukkit.jar`
    end
    if(!OPTIONS.persistent)
      break
    elsif 
      output "Waiting on PID #{pid} (because -p specified)"
      wait(pid)
      output "Restarting..."
    end 
  end #while
end

output "Done."
