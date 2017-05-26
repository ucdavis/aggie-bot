Aggie Bot
=========

Version 0.74 2017-05-26

Aggie Bot is a Slack-compatible chat bot designed for use by the
UC Davis IT community. It originated in the UC Davis Division of Social
Science IT group.

Requirements
------------
 * Ruby 2.1 or higher (2.0 and 1.9 may work but have not been tested)
 * The popular 'bundler' gem ('gem install bundler' to install it)
 * A working SysAid server (for optional SysAid support)
 * A working Roles Management server (for optional Roles Management support)
 * Admin access to a Slack workgroup

Installation Instructions
-------------------------
 1. Place the aggie-bot folder where you prefer to keep web applications.
 2. 'cd' into 'aggie-bot' and run 'bundle install'
 3. Copy config/settings.example.yml to config/settings.yml and ensure each
    setting is configured correctly.
 4. Run ./aggie-bot.rb start (also repsonds to status, stop, and restart)

Usage
-----
Once you have chosen a username for Aggie Bot (we'll assume it's @bot in this
documentation), invite @bot to the room you'd like to use it in.

You can then type commands in the form: "<command> <query>", e.g. "ldap smith"
to perform an LDAP lookup using the query term "smith".

LDAP Attribute-Specific Search
------------------------------
When using the 'ldap' command, you can narrow your search to a specific field
if you wish, e.g. "ldap last smith" will search only the last name attribute
for 'smith' or e.g. "ldap loginid smith" will search only the login ID attribute
(usually 'uid' in LDAP) for the term 'smith'. Below are the possible fields
and their LDAP mappings:

  'uid', 'login', 'loginid', 'kerberos' will search the 'uid' attribute.
  'name', 'displayname', 'fullname'     will search the 'displayName' attribute.
  'givenname', 'first', 'firstname'     will search the 'givenName' attribute.
  'sn', 'last', 'lastname'              will search the 'sn' attribute.
  'mail', 'email', 'e-mail'             will search the 'mail' attribute.
  'department', 'dept', 'ou'            will search the 'ou' attribute.
  'affiliation', 'ucdpersonaffiliation' will search the 'ucdPersonAffiliation' attribute.

Contact
-------
Christopher Thielen, Lead Application Developer UCD DSS IT
