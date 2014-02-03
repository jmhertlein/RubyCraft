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
  attr_accessor :server_name, :server_dir, :backup_dir, :screen_name, :pid

  def initialize(server_name, server_dir, backup_dir)
    @server_name = server_name
    @server_dir = server_dir
    @backup_dir = backup_dir
  end

  def start()
    Dir.chdir(@server_dir)
    @screen_name = "mc-" + @server_name.gsub(" ", "-")
    @pid = spawn("screen -d -m -S #{@screen_name} java -jar craftbukkit.jar")
  end

  def halt()
    spawn("screen -S #{@screen_name} -p 0 -X stuff '\nstop\n'")
  end

  def kill
    Process.kill(9, @pid)
  end

  def isRunning?
    if(@pid.nil?)
      return false
    end
    return !(`screen -ls`.scan(/#{@screen_name}/).empty?)
  end

  def backup()
    getWorldDirs().each do |worldDir|
      backupFileName = "#{worldDir.basename}_#{DateTime.now.to_s}.zip"
      backupFilePathname = Pathname.new(@backup_dir) + backupFileName
      `zip -9 -r #{backupFilePathname.realdirpath} #{worldDir.realpath}`
    end
  end

  def getWorldDirs()
    worlds = []
    Dir.glob("#{@server_dir}/**/level.dat").each do |dat|
      serverFolder = Pathname.new(dat).parent  
      worlds << serverFolder
    end

    return worlds
  end
end
