# RubyCraft 

## Synopsis

### Batch

    rc -i                       # launch interactively 
    rc -b -s notchland          # backup the server named 'notchland'
    rc --prune=10 -s notchland  # prune backups of the server named 'notchland' older than 10 days
    rc -p=/path/to/profile ...  # specify a profile location other than ~/.rcraft_profile
    rc -w 30 -r -s notchland    # restart notchland with a 30 second warning printed to players
    rc --help                   # print help, and more options

### Interactive

    r - Register a server   - Lets you specify a name, a directory in which the server resides, and a 
                                directory in which to store backups of the server's worlds.
    u - Unregister a server - Makes rc forget the server - does not delete it from disk
    s - Start a server      - starts the server running in a new GNU screen session in multiuser mode
    e - Restart a server    - halts a server, then starts it again.
    h - Halt a server       - cleanly stops the server and terminates the GNU screen
    l - List servers        - Lists all servers registered with rc, as well as their status 
                                (up = server is running, down = server is not running)
    b - Backup a server     - Backs up a server's worlds to its backup directory
    p - Prune backups       - Remove backups of a server that are older than a certain number of days
    v - View a server       - exits rc and attaches you to the GNU screen in which the specified 
                                server is running
    x - Exit                - Exits rc. (Does not halt servers- if they're running, they keep running).

There's a help menu in the interactive prompt, so don't worry about memorizing these.

In order to perform a backup (rc -b) the server needs to be registered. To do this, launch the program interactively (rc -i) and enter 'r'.
