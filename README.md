# RubyCraft 

## Installation

In the interest of conserving entropy, I've opted not to upload this to rubygems. You should build locally.

    git clone https://github.com/jmhertlein/RubyCraft.git
    cd RubyCraft
    gem build rubycraft

    # install globally
    sudo gem install --no-user-install ./rubycraft-*.gem

    # clean up
    rm ./rubycraft-*.gem


## Updating

Quite similar to installation.

    # if you still have the directory around,
    cd RubyCraft
    git pull

    # otherwise
    git clone https://github.com/jmhertlein/RubyCraft.git
    cd RubyCraft

    # then just repeat the install directions.
    gem build rubycraft

    # install globally
    sudo gem install --no-user-install ./rubycraft-*.gem

    # clean up
    rm ./rubycraft-*.gem

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

### Cron

Batch mode is great for use with cron.

I like to use `crontab -e` as my "minecraft" user to edit its crontab.

    0 5 * * * rc -b -s notchland          # backup every night at 5am
    10 5 * * * rc --prune=3 -s notchland  # prune backups every night at 5:10AM
    0 6 * * * rc -w 30 -r -s notchland    # reboot every night (w/ 30s warning) at 6AM

Make sure rc is in the PATH that's set for cron.
