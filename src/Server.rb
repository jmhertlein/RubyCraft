class Server
  attr_accessor :server_name, :server_dir, :backup_dir, :screen_name, :pid

  def initialize(server_name, server_dir, backup_dir)
    @server_name = server_name
    @server_dir = server_dir
    @backup_dir = backup_dir
  end
end
