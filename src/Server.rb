class Server
  attr_accessor :name, :server_dir, :backup_dir, :screen_name, :persistent, :pid

  def initialize(server_dir, backup_dir, persistent=false)
    @server_dir = server_dir
    @backup_dir = backup_dir
  end
end
