DSS ChatBot
===========

DSS ChatBot is a Slack-compatible chat bot designed for use within the
UC Davis Division of Social Science IT group.

Requirements
------------
 * Ruby 2.1 or higher (2.0 and 1.9 may work but have not been tested)
 * The popular 'bundler' gem ('gem install bundler' to install it)
 * A working SysAid server
 * Admin access to a Slack workgroup

Installation Instructions
-------------------------
 1. Place the dss-chatbot folder where you prefer to keep web applications.
 2. 'cd' into 'dss-chatbot' and run 'bundle install'
 3. Copy config/settings.example.yml to config/settings.yml and ensure each
    setting is configured correctly.
 4. Run ./dss-chatbot.rb start (also repsonds to status, stop, and restart)

Contact
-------
Christopher Thielen, Lead Application Developer UCD DSS IT
