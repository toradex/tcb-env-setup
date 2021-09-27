# tcb-env-setup

TorizonCore Builder Environment Setup Script

## Usage
### Basic Use
To use the setup script in interactive mode run it as follows with no arguments:
```
source tcb-env-setup.sh
```
**IMPORTANT**: Make sure you execute the script by sourcing it as shown above. Executing it normally will cause certain parts of the setup to fail and most importantly the `torizoncore-builder` command will not be available to you.

The script will guide you through some yes/no prompts. By the end the script will setup Torizoncore-builder with either the latest version of the tool found locally or online depending on your anwsers. On success you can then use the tool by running `torizoncore-builder`. Finally you must run this setup script every new terminal session as the `torizoncore-builder` command will not be retained through sessions.

### Advanced Usage and Options
The script supports the following options:

- `-a <value>`           (a)uto mode 
                         With this flag enabled the script will automatically run with no need for user input. Valid values for <value> are either `remote` or `local`.
                         When `-a remote` is passed the script will automatically use the latest version of TorizonCore Builder online, with no consideration for any local versions that may exist.
                         When `-a local` is passed the script will automatically use the latest version of TorizonCore Builder found locally, with no consideration to what may be online.
                         This flag is mutually exclusive with the `-t` flag.

- `-t <version tag>`     (t)ag mode.
                         With this flag enabled the script will automatically run with no need for user input. Valid values for <version tag> can be found online [here](https://registry.hub.docker.com/r/torizon/torizoncore-builder/tags?page=1&ordering=last_updated).
                         Whatever <version tag> is provided will then be pulled from online.
                         This flag is mutually exclusive with the `-a` flag.

- `-d`                   (d)isable volumes."
                         With this flag enabled the script will setup torizoncore-builder without Docker volumes.
                         Meaning some torizoncore-builder commands will require additional directories to be passed as arguments.
                         By default with this flag excluded torizoncore-builder is setup with Docker volumes.

- `-s`                   (s)torage directory.
                         Internal directory that TorizonCore Builder should use to keep its state information.
                         If this flag was not set, the "storage" Docker volume will be used.

- `-h`                   (h)elp
                         Prints usage information.
