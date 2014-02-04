# RubyCraft 

## Synopsis

### Batch

    rc -i          # launch interactively 
    rc -b server   # backup the specified server
    rc --help      # print help

### Interactive

    r - Register a server   - Lets you specify a name, a directory in which the server resides, and a directory in which to store backups of the server's worlds.
    u - Unregister a server - Makes rc forget the server - does not delete it from disk
    s - Start a server      - starts the server running in a new GNU screen session in multiuser mode
    e - Restart a server    - halts a server, then starts it again.
    h - Halt a server       - cleanly stops the server and terminates the GNU screen
    k - Kill a server       - Sends POSIX signal 9 (SIGKILL) to the GNU screen session that the server is in
    l - List servers        - Lists all servers registered with rc, as well as their status (up = server is running, down = server is not running)
    b - Backup a server     - Backs up a server's worlds to its backup directory
    v - View a server       - exits rc and attaches you to the GNU screen in which the specified server is running
    x - Exit                - Exits rc. (Does not halt servers- if they're running, they keep running).

There's a help menu in the interactive prompt, so don't worry about memorizing these.

In order to perform a backup (rc -b) the server needs to be registered. To do this, launch the program interactively (rc -i) and enter 'r'.
