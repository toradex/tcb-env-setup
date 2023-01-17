# tcb-env-setup

TorizonCore Builder Environment Setup Script

## Usage

### Basic Use (latest official release)

To use the setup script in interactive mode run it as follows with no arguments:

```
source tcb-env-setup.sh
```

**IMPORTANT**: Make sure you execute the script by sourcing it as shown above. Executing it normally
will cause certain parts of the setup to fail and most importantly the `torizoncore-builder`
command will not be available to you.

The script will guide you through some yes/no prompts. By the end the script will setup TorizonCore
Builder with either the latest version of the tool found locally or online depending on your answers.
On success you can then use the tool by running `torizoncore-builder`. Finally you must run this
setup script every new terminal session as the `torizoncore-builder` command will not be retained
through sessions.

**NOTE (for Windows users only)**: Extra parameters may be needed if you intend to use the tool as
a server (i.e. run `torizoncore-builder` commands such as `images serve` or `ostree serve`).
Please refer to the documentation of these commands for more information.

### Basic Use (early-access version)

Toradex generates an early-access version of TorizonCore Builder on a weekly basis. That version has
the latest implementations made by the R&D team, including bug fixes and new features not officially
released. New features will not be documented yet and may not be fully functional; also their
interface may change before the official release. Because of that, we recommend the use of the
early-access version only in case one is being affected by some bug whose fix is already available
in that version. Notice though that we do not have a release notes document for such a version so
that the information about the fixes available would most likely come from Toradex support.

If you want to try this version then source the setup script passing the `early-access` tag, e.g.:

```
$ source tcb-env-setup.sh -t early-access
```

Other than passing the tag, usage of the setup script is just the same as with the official release.

### Advanced Usage and Options

Here is the help output of the script obtained via `source tcb-env-setup.sh -h`:

```
Usage: source tcb-env-setup.sh [OPTIONS] [-- <docker_options>]

optional arguments:
  -a <value>: select auto mode
      With this flag enabled the script will automatically run with no need
      for user input. Valid values for <value> are either remote or local.
      When "-a remote" is passed, the script will automatically use the
      latest version of TorizonCore Builder online, with no consideration
      for any local versions that may exist. When "-a local" is passed
      the script will automatically use the latest version of TorizonCore
      Builder found locally, with no consideration to what may be online.
      This flag is mutually exclusive with the -t flag.

  -t <version tag>: select tag mode
      With this flag enabled the script will automatically run with no need
      for user input. Valid values for <version tag> can be found online:
      https://registry.hub.docker.com/r/torizon/torizoncore-builder/tags?page=1&ordering=last_updated.
      Whatever <version tag> is provided will then be pulled from online.
      This flag is mutually exclusive with the -a flag.

  -d: disable volumes
      With this flag enabled the script will setup torizoncore-builder
      without Docker volumes meaning some torizoncore-builder commands will
      require additional directories to be passed as arguments. By default
      with this flag excluded torizoncore-builder is setup with Docker
      volumes.

  -s: select storage directory or Docker volume
      Internal storage directory or Docker volume that TorizonCore Builder
      should use to keep its state information and image customizations.
      It must be an absolute directory or a Docker volume name. If this
      flag is not set, the "storage" Docker volume will be used.

  -n: do not enable "host" network mode.
      Under Linux the tool runs in "host" network mode by default allowing
      it to operate as a server without explicit port publishing. Under
      Windows this mode of operation is always disabled requiring port
      publishing to be set up if the tool is to act as a server. This flag
      disables the default behavior (which is relevant under Linux).

  -- <docker_options>: extra options to be passed to "docker run".
       Parameters after -- are simply forwarded to the "docker run"
       invocation in the alias that the script creates.

  -h: help
       Prints usage information.
```
