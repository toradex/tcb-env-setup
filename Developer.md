# Development/Design Guidelines:

 - The setup script must be backward compatible when setting up older TorizonCore
   Builder versions.

 - The auto-completion script will only be active if the user has setup the latest
   TorizonCore Builder. If they setup an older version, then auto-completion will
   not be available.

 - There can be no dependency between the auto-completion script and the setup
   script. All the setup script can do is download and source the latest auto-
   completion script.

 - An effort should be made to keep TorizonCore Builder compatible with older
   versions of the setup script; when any piece of information that is 
   supposed to be passed by the setup script alias is not available to its 
   container, TorizonCore Builder should show appropriate messages to let the 
   user know about that fact.
