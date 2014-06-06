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
  options.profile_file = ENV['HOME'] + "/.config/rcraft_profile"

  #options parsing
  opt_parser = OptionParser.new do |opts|
    opts.banner = USAGE

    opts.on("-b", "--backup", "Backup a registered server.") do |b|
      options.batch = true
      options.backup = !b.nil?
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

  jars = s.getPossibleServerJarPathnames
  if(jars.size == 1)
    s.server_jar = jars[0].basename
    puts "Selected #{jars[0].basename}"
  else
    puts "Found more than one jar in #{server_dir}. Which number is the jar to start the server? (default=0)"
    jars.each_with_index do |jar, n|
      puts "    #{n}. #{jar.basename}"
    end
    num = gets.chomp.to_i
    puts "Selected #{jars[num].basename}"
    s.server_jar = jars[num].basename
  end

  jvmargs = "-Xmx1G -XX:MaxPermSize=128M"
  puts "Default JVM arguments are: #{jvmargs}"
  puts "Enter custom arguments or press enter to accept default."
  newargs = gets.chomp
  if(!newargs.empty?)
    jvmargs = newargs
  end
  puts "JVM arguments set to: #{jvmargs}"
  s.java_args = jvmargs
end

def restartServer(servers)
  puts "Name of server to restart:"
  server = gets.chomp
  server = servers[server]

  if(server.nil?)
    puts "Unknonw server."
  elsif(!server.isRunning?)
    puts "Server is not running."
  else
    server.restart
  end
end

def listServers(servers)
  servers.each do |key, value|
    if(value.isRunning?)
      status = "up"
    else
      status = "down"
    end

    puts "#{value.server_name} | #{status}"
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

def viewServer(servers)
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

def pruneBackups(servers)
  puts "Name of server whose backups will be pruned:"
  server = gets.chomp
  server = servers[server]

  puts "Delete backups older than how many days?"
  days = gets.chomp.to_i
  
  pending = server.getBackupPathnamesOlderThan(days)
  puts "===========PENDING DELETIONS====================="
  pending.each do |pend|
    puts pend.realpath
  end
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

def printMenu()
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

# ------------------------MAIN-------------------------

OPTIONS = parseOptions(ARGV)

lockfile = Pathname.new "/tmp/rcraft-#{ENV['USER']}.pid"
if(lockfile.exist?)
  pid = "unknown"
  lockfile.open {|f| pid = f.read }
  puts "Your user is already running an instance of rcraft. (PID: #{pid})"
  puts "If this pid is dead, remove the file #{lockfile} to quash this message."
  exit(1)
else
  FileUtils.touch(lockfile)
  lockfile.open "w" do |stream|
    stream.write Process.pid
  end
end

def output(msg)
  if(OPTIONS.verbose)
    puts msg
  end
end

output "Options: #{OPTIONS}"

if(!OPTIONS.batch && !OPTIONS.interactive)
  puts "No actions specified, nothing to do."
  exit
end

if(OPTIONS.batch && OPTIONS.interactive)
  puts "Both batch and interactive modes requested, but this isn't supported."
  puts "Please either use bath or interactive mode, but not both at once."
  exit
end

SERVERS = loadProfile(OPTIONS.profile_file)

#-------------------------init done-------------------

#-------------------------batch-----------------------
if(OPTIONS.batch)
  server = OPTIONS.server
  if(server.nil?)
    puts "No server specified. Specify one with --server."
    exit
  end

  server = SERVERS[OPTIONS.server]
  if(server.nil?)
    puts "Unknown server: " + OPTIONS.server
    exit
  end

  #------------------backup------------------------
  if(OPTIONS.backup)
    output "Backing up server: " + server.to_s
    output "Detected worlds: "
    server.getWorldDirs.each do |d|
      output d.basename
    end

    output "Backing up..."
    server.backup
    output "Backed up."
  #----------------prune---------------------------
  elsif(OPTIONS.prune)
    output "Pruning server: #{server.to_s}"

    if(OPTIONS.prune_days <= 0)
      puts "Error: can only prune backups >= 1 day old. (You specified #{OPTIONS.prune_days})"
      exit
    end

    pending = server.getBackupPathnamesOlderThan(OPTIONS.prune_days)
    output "===========PENDING DELETIONS====================="
    pending.each do |pend|
      output pend.realpath
    end
    output "================================================="

    output "This will delete #{pending.size} files."
    output "Pruning..."
    server.pruneBackups(OPTIONS.prune_days)
    output "Done pruning."
#------------------------restart-------------------------
  elsif(OPTIONS.restart)
    output "Restarting..."
    if(OPTIONS.warn)
      output "Issuing warning and waiting #{OPTIONS.warn_time} seconds."
      server.puts "Restarting in #{OPTIONS.warn_time} seconds."
      sleep(OPTIONS.warn_time)
    end
    server.restart
    output "Restarted."
  else
    puts "No batch operations specified, nothing to do."
  end
#-------------------------interactive-----------------
elsif(OPTIONS.interactive)
  stop = false
  printMenu()
  while(!stop)
    print ">"
    STDOUT.flush
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
      when "v"
        writeProfile(OPTIONS.profile_file, SERVERS)
        viewServer(SERVERS)
      when "ls"
        listServers(SERVERS)
      when "l"
        listServers(SERVERS)
      when "b"
        backupServer(SERVERS)
      when "p"
        pruneBackups(SERVERS)
      when "e"
        restartServer(SERVERS)
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
lockfile.unlink
output "rc exiting."
