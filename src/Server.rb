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
require 'find'

class Server
  attr_accessor :server_name, :server_dir, :backup_dir, :screen_name, :server_jar, :java_args

  def initialize(server_name, server_dir, backup_dir)
    @server_name = server_name
    @server_dir = server_dir
    @backup_dir = backup_dir
    @screen_name = "mc-" + @server_name.gsub(" ", "-")
  end

  def start()
    Dir.chdir(@server_dir)
    spawn("screen -d -m -S #{@screen_name} java #{@java_args} -jar #{@server_jar}")
    while(!self.isRunning?)
      sleep 1
    end
    spawn("screen -S #{@screen_name} -p 0 -X multiuser on")
  end

  def halt()
    spawn("screen -S #{@screen_name} -p 0 -X stuff '\nstop\n'")
  end

  def sigint
    spawn "kill -2 #{self.screen_pid}"
  end

  def sigkill
    spawn "kill -9 #{self.screen_pid}"
    sleep 5
    spawn "screen -wipe"
  end

  def say(msg)
    spawn("screen -S #{@screen_name} -p 0 -X stuff '\nsay #{msg}\n'")
  end

  def restart()
    timeout = 60*5 #5 mins
    maxTries = 3

    started = false
    tries = 0
    while tries < maxTries && !started do
      puts "try #{tries}"
      puts "issuing halt"
      self.halt
      elapsed = 0
      while(self.isRunning? && elapsed < timeout)
        puts "not stopped (#{elapsed})"
        sleep 1
        elapsed += 1
      end
      puts "stopped or timed out"
      if(!self.isRunning?)
        puts "Starting"
        self.start
        started = true
      else
        puts "Wasn't stopped, retrying"
        tries += 1
      end
    end

    if !started
      puts "ERROR: COULDN'T STOP SERVER"
      puts "SENDING SIGINT TO SERVER"
      self.sigint
      puts "WAITING 10s TO SEE IF SIGINT KILLS IT..."
      sleep(10)
      if self.isRunning?
        puts "BUCKET IS OFFICIALLY KICKED, SENDING SIGKILL"
        self.sigkill
        sleep(5)
      end

      if isRunning?
        puts "PROCESS IS IMMORTAL (sigkill wasn't able to kill)"
        puts "Giving up, good luck, have fun."
      else
        puts "Server died to signal, restarting."
        self.start
        puts "Started server"
      end
    end
  end

  def isRunning?
    return !(`screen -ls`.scan(/#{@screen_name}/).empty?)
  end

  def backup()
    getWorldDirs().each do |worldDir|
      worldName = worldDir.basename
      backupFileName = "#{worldName}_#{Date.today.to_s}.zip"
      worldBackupPathname = Pathname.new(@backup_dir) + worldName
      worldBackupPathname.mkpath
      backupFilePathname = worldBackupPathname +  backupFileName
      `zip -9 -r #{backupFilePathname.realdirpath} #{worldDir.realpath}`
    end
  end

  def getWorldDirs()
    worlds = []
    Dir.glob("#{@server_dir}/*/level.dat").each do |dat|
      serverFolder = Pathname.new(dat).parent  
      worlds << serverFolder
    end

    return worlds
  end

  def getBackupPathnamesOlderThan(days)
    backups = Pathname.new @backup_dir
    oldFiles = []

    worldBackupDirs = []
    
    getWorldDirs().each do |worldDir|
      worldBackupDirs << (backups + worldDir.basename.to_s)
    end
    worldBackupDirs.each do |backupDir|
      Pathname.glob("#{backupDir.realpath.to_s}/**/*.zip").each do |zipfile|
        timestamp = zipfile.basename.to_s.chomp(".zip").split("_")[-1]
        if(timestamp.empty? or timestamp == zipfile.basename.to_s.chomp(".zip"))
          next
        end
        begin
          date = Date.parse timestamp
        rescue
          next
        end
        if((Date.today - date).to_int > days)
          oldFiles << zipfile
        end
      end #glob
    end #worldBackupDirs
    return oldFiles
  end

  def pruneBackups(days)
    getBackupPathnamesOlderThan(days).each do |oldBackup|
      oldBackup.delete
    end
  end

  def getPossibleServerJarPathnames()
    return Pathname.glob("#{@server_dir}/*.jar")
  end

  def to_s
    return "[#{@server_name} (Location: #{@server_dir}) (Backup: #{@backup_dir})]"
  end

  def screen_pid
    pid = `screen -ls`.scan(/(?<=^\t)[0-9]+(?=\.#{@screen_name}.*$)/).to_i
    if pid == 0
      return -1
    else
      return pid
    end
  end
end
