#!/usr/bin/env ruby

# Copyright (C) 2014 Joshua Michael Hertlein <jmhertlein@gmail.com>
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
require 'yaml'
require 'fileutils'
require 'pathname'

require_relative 'Server.rb'

USAGE = "Usage: rc [OPTIONS] "

def parseOptions(args)
  options = OpenStruct.new
  options.backup = false
  options.interactive = false
  options.verbose = false
  options.profile_file = ENV['HOME'] + "/.rcraft_profile"

  opt_parser = OptionParser.new do |opts|
    opts.banner = USAGE

    opts.on("-b=SERVER", "--backup=SERVER", "Backup a registered server.") do |b|
      options.backup = !b.nil?
      options.server = b
    end
    
    opts.on("-p=PROFILE_FILE", "--profile=PROFILE_FILE", "File to which persistent state will be written. (Default: ~/.rcraft_profile") do |p|
      options.profile_file = p
    end

    opts.on("-i", "--interactive", "Launch interactive server manager.") do |i|
      options.interactive = i
    end

    opts.on("-v", "--verbose", "Print verbose output.") do |v|
      options.verbose = v
    end

  end.parse!
    
  return options
end

def loadProfile(profile_file) 
  FileUtils.touch(profile_file)

  file = File.open(profile_file)
  servers = YAML.load(file.read)
  if(!servers)
    servers = Hash.new
  end
  file.close

  return servers
end

def writeProfile(profile_file, servers)
  file = File.open(profile_file, 'w')
  file.write(servers.to_yaml)
  file.close
end

#------------------Menu Functions-----------------------------------

def registerServer(servers)
  puts "Server Name: (for display purposes, should be unique)"
  server_name = gets.chomp
  puts "Server directory:"
  server_dir = File.expand_path(gets.chomp)
  puts "Backup directory:"
  backup_dir = File.expand_path(gets.chomp)

  s = Server.new(server_name, server_dir, backup_dir)
  servers[server_name] = s
end

def listServers(servers)
  puts servers
  servers.each do |key, value|
    puts key
  end
end

def unregisterServer(servers)
  puts "Name of server to delete:"
  server = gets.chomp
  if(servers.has_key?(server))
    servers.delete(server)
  elsif
    puts "Unknown server."
  end
end

def startServer(servers)
  puts "Name of server to start:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknonw server."
  elsif(server.isRunning?)
    puts "Server is already running."
  else
    server.start
  end
end

def haltServer(servers)
  puts "Name of server to halt:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknonw server."
  elsif(!server.isRunning?)
    puts "Server is already halted."
  else
    server.halt
  end
end

def backupServer(servers)
  puts "Server name:"
  server = SERVERS[gets.chomp]

  if(server.nil?)
    puts "Unknown server."
  else
    puts "Backing up..."
    server.backup
    puts "Done backing up."
  end
end

def killServer(servers)
  puts "Name of server to kill:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknown server."
  elsif(server.isRunning?)
    puts "Server is not running."
  else
    server.kill
  end
end

def viewServer(servers)
  puts "Not yet implemented."
end

def printMenu()
  puts "Usage: [char] [argument]"
  puts "======================="
  puts "(r)egister a server"
  puts "(u)nregister a server"
  puts "(s)tart a server"
  puts "(h)alt a server"
  puts "(k)ill a server"
  puts "(l)ist servers"
  puts "(b)ackup a server's worlds"
  puts "(v)iew a server"
  puts "e(x)it"
  puts "Print (help)"
  puts"========================"
end

# ------------------------MAIN-------------------------

OPTIONS = parseOptions(ARGV)

def output(msg)
  if(OPTIONS.verbose)
    puts msg
  end
end

output "Options: #{OPTIONS}"

if(!OPTIONS.backup && !OPTIONS.interactive)
  puts "No actions specified, nothing to do."
  exit
end

if(OPTIONS.backup && OPTIONS.interactive)
  puts "Both backup and interactive mode requested, but this isn't supported."
  puts "Please either backup or run interactively, but not both at once."
  exit
end

SERVERS = loadProfile(OPTIONS.profile_file)

#-------------------------init done-------------------

#-------------------------batch-----------------------
if(OPTIONS.backup)
  server = SERVERS[OPTIONS.server]
  if(server.nil?)
    puts "Unknown server: " + OPTIONS.server
    exit
  end

  output "Backing up server: " + server.to_s
  output "Detected worlds: "
  server.getWorldDirs.each do |d|
    output d.basename
  end

  output "Backing up..."
  server.backup
  output "Backed up."
#-------------------------interactive-----------------
elsif(OPTIONS.interactive)
  stop = false
  printMenu()
  while(!stop)
    char = gets.chomp
    case char
      when "r"
        registerServer(SERVERS)
      when "u"
        unregisterServer(SERVERS)
      when "s"
        startServer(SERVERS)
      when "h"
        haltServer(SERVERS)
      when "k"
        killServer(SERVERS)
      when "v"
        viewServer(SERVERS)
      when "ls"
        listServers(SERVERS)
      when "l"
        listServers(SERVERS)
      when "b"
        backupServer(SERVERS)
      when "x"
        stop = true
      when "help"
        printMenu()
      else
        puts "Invalid command: \"#{char}\"."
        printMenu()
    end #case
  end #while
end #if

#---------------------shutdown-----------------------
writeProfile(OPTIONS.profile_file, SERVERS)
output "Done."
