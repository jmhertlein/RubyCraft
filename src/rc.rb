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
require_relative 'menu.rb'

# ------------------------MAIN-------------------------

OPTIONS = parseOptions(ARGV)
p = Pathname.new OPTIONS.profile_dir
p.mkpath
CONFIG = loadConfig(OPTIONS.config_file)

lockfile = Pathname.new "/tmp/rcraft-#{ENV['USER']}.pid"
if(lockfile.exist?)
  pid = "unknown"
  lockfile.open {|f| pid = f.read }
  puts "Your user is already running an instance of rcraft. (PID: #{pid})"
  puts "If this pid is dead, remove the file #{lockfile} to quash this message."

  unless CONFIG[:admin_emails].nil?
    puts "Emailing admin..."
    CONFIG[:admin_emails].each do |email|
      spawn("echo 'rcraft error: already running!\noptions:\n\n#{OPTIONS}' | mail -s \"rubycraft error\" #{email}")
    end
  end
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

SERVERS = loadProfile(OPTIONS.servers_file)

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
        hcf OPTIONS, SERVERS, lockfile
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
hcf OPTIONS, SERVERS, lockfile
