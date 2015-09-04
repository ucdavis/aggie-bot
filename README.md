DSS ChatBot
===========

DSS ChatBot is a HipChat-compatible chat bot designed for use within the
UC Davis Division of Social Science IT group.

Requirements
------------
 * Ruby 2.1 or higher (2.0 and 1.9 may work but have not been tested)
 * The popular 'bundler' gem ('gem install bundler' to install it)
 * A working SysAid server
 * A publicly-visible HTTPS site on the web (a requirement of being a HipChat add-on)
 * A Rack-compatible server (Apache+Passenger, nginx+Unicorn, etc.)
 * Admin access to a HipChat account

Installation Instructions
-------------------------
 1. Place the dss-chatbot folder where you prefer to keep web applications.
 2. Configure your (Ruby) Rack server to use the application.
 3. 'cd' into 'dss-chatbot' and run 'bundle install'
 4. Copy config/settings.example.yml to config/settings.yml and ensure each
    setting is configured correctly.
 5. Test your installation by loading https://the-configured-url/capabilities
 6. If all works, register the add-on using HipChat's "Integrations" tab under
    "Group Admin".

Commands
--------
 * /sysaid <1234> (Fetches information about SysAid ticket \#1234)

Contact
-------
Christopher Thielen, Lead Application Developer UCD DSS IT
