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

require 'rubycraft/server'

USAGE = "Usage: rc [OPTIONS]"

def parseOptions(args)
  options = OpenStruct.new

  #modes
  options.interactive = false
  options.batch = false
  options.verbose = false
  
  #batch options
  options.backup = false
  options.prune = false
  options.server = nil
  options.restart = false
  options.warn = false
  
  #profile
  options.profile_dir = File.join(Dir.home, ".config", "rubycraft")
  options.servers_file = File.join(options.profile_dir, "servers.yml")
  options.config_file = File.join(options.profile_dir, "config.yml")

  #options parsing
  opt_parser = OptionParser.new do |opts|
    opts.banner = USAGE

    opts.on("-b", "--backup", "Backup a registered server.") do |b|
      options.batch = true
      options.backup = !b.nil?
    end
    
    opts.on("-p=PROFILE_FILE", "--profile=PROFILE_FILE", "File to which persistent state will be written. (Default: ~/.rcraft_profile") do |p|
      options.servers_file = p
    end

    opts.on("-i", "--interactive", "Launch interactive server manager.") do |i|
      options.interactive = i
    end

    opts.on("-v", "--verbose", "Print verbose output.") do |v|
      options.verbose = v
    end

    opts.on("--prune=DAYS", "Prune backups older than DAYS days") do |prune|
      options.batch = true
      options.prune = true
      options.prune_days = prune.to_i
    end

    opts.on("-s=NAME", "--server=NAME", "Specify the server to operate on in batch mode") do |s|
      options.batch = true
      options.server = s
    end

    opts.on("-r", "--restart", "Restart a server.") do |r|
      options.batch = true
      options.restart = true
    end

    opts.on("-w=SECS", "--warn=SECS", "Warn server SECS seconds before an action, if applicable.") do |w|
      options.batch = true
      options.warn = true
      options.warn_time = w.to_i
    end
  end.parse!
    
  return options
end

def loadProfile servers_file
  FileUtils.touch(servers_file)

  servers = nil
  File.open(servers_file) {|f| servers = YAML.load(f.read) }
  servers = Hash.new if !servers

  return servers
end

def writeProfile servers_file, servers
  File.open(servers_file, 'w') {|f| f.write servers.to_yaml }
end

def loadConfig config_file
  FileUtils.touch(config_file)

  config = false
  File.open(config_file) { |f| config = YAML.load(f.read) }
  unless config
    config = Hash.new
    config[:admin_emails] = [ENV['USER']]
    File.open(config_file, 'w') {|f| f.write(config.to_yaml)}
  end

  return config
end

##
# Prepare for shutdown
def hcf options, servers
  writeProfile(options.servers_file, servers) unless servers.nil?
  output "rc exiting."
end

#------------------Menu Functions-----------------------------------

def registerServer servers
  puts "Server Name: (for display purposes, should be unique)"
  server_name = gets.chomp
  puts "Server directory:"
  server_dir = File.expand_path(gets.chomp)
  puts "Backup directory:"
  backup_dir = File.expand_path(gets.chomp)

  if !File.exist? server_dir
    puts "Server dir \"#{server_dir}\" does not exist."
    return
  end

  if !File.exist? backup_dir
    puts "Backup dir \"#{backup_dir}\" does not exist."
    return
  end

  s = Server.new(server_name, server_dir, backup_dir)

  jars = s.getPossibleServerJarPathnames
  if(jars.size == 1)
    s.server_jar = jars[0].basename
    puts "Selected #{jars[0].basename}"
  elsif jars.size == 0
    puts "Found no JARs in the server dir \"#{server_dir}\""
    puts "Please move a minecraft/spigot/etc JAR into the server dir."
    return
  else
    puts "Found more than one jar in #{server_dir}. Which number is the jar to start the server? (default=0)"
    jars.each_with_index do |jar, n|
      puts "    #{n}. #{jar.basename}"
    end
    num = gets.chomp.to_i
    puts "Selected #{jars[num].basename}"
    s.server_jar = jars[num].basename
  end

  puts "Enter the path to the java executable you wish to use, or blank for PATH's java"
  java_path = gets.chomp
  if java_path.empty?
    puts "Using PATH's java"
  else
    s.java_path = Pathname.new(java_path)
    puts "Java executable set to #{s.java_path}"
  end

  jvmargs = "-XX:+UseG1GC -Xmx1G -XX:MaxPermSize=128M"
  puts "Default JVM arguments are: #{jvmargs}"
  puts "Enter custom arguments or press enter to accept default."
  newargs = gets.chomp
  if(!newargs.empty?)
    jvmargs = newargs
  end
  puts "JVM arguments set to: #{jvmargs}"
  s.java_args = jvmargs

  servers[server_name] = s
end

def restartServer servers
  puts "Name of server to restart:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknown server."
  elsif(!server.isRunning?)
    puts "Server is not running."
  else
    server.restart
  end
end

def listServers servers
  servers.each do |key, value|
    if(value.isRunning?)
      status = "up"
    else
      status = "down"
    end

    puts "#{value.server_name} | #{status}"
  end
end

def unregisterServer servers
  puts "Name of server to unregister:"
  server = gets.chomp
  if(servers.has_key?(server))
    servers.delete(server)
    puts "Server unregistered."
  elsif
    puts "Unknown server."
  end
end

def startServer servers
  puts "Name of server to start:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknown server."
  elsif(server.isRunning?)
    puts "Server is already running."
  else
    server.start
  end
end

def haltServer servers
  puts "Name of server to halt:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknown server."
  elsif(!server.isRunning?)
    puts "Server is already halted."
  else
    server.halt
  end
end

def backupServer servers
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

def viewServer servers
  puts "Name of server to view:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknown server."
  elsif(!server.isRunning?)
    puts "Server is not running."
  else
    exec("screen -x #{server.screen_name}")
  end
end

def pruneBackups servers
  puts "Name of server whose backups will be pruned:"
  server = gets.chomp
  server = servers[server]

  puts "Delete backups older than how many days?"
  days = gets.chomp.to_i
  
  pending = server.getBackupPathnamesOlderThan(days)
  puts "===========PENDING DELETIONS====================="
  pending.each {|pend| puts pend.realpath}
  puts "================================================="

  puts "This will delete #{pending.size} files. Proceed? (y/N)"
  resp = gets.chomp

  if(server.nil?)
    puts "Unknown server."
  elsif(resp != "y")
    puts "Deletion aborted."
  else
    puts "Deleting..."
    server.pruneBackups(days)
    puts "Deleted."
  end
end

def printMenu
  puts "Usage: [char] [argument]"
  puts "======================="
  puts "(r)egister a server"
  puts "(u)nregister a server"
  puts "(s)tart a server"
  puts "r(e)start a server"
  puts "(h)alt a server"
  puts "(l)ist servers"
  puts "(b)ackup a server's worlds"
  puts "(p)rune backups of a server's worlds"
  puts "(v)iew a server"
  puts "e(x)it"
  puts "Print (help)"
  puts"========================"
end
