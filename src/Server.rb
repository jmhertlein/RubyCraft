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

class Server
  attr_accessor :server_name, :server_dir, :backup_dir, :screen_name, :pid

  def initialize(server_name, server_dir, backup_dir)
    @server_name = server_name
    @server_dir = server_dir
    @backup_dir = backup_dir
  end
end