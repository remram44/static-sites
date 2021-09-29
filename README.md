Static sites deployment script
==============================

This script can be used to deploy multiple websites to a web server, by pulling them from Git repositories (for example on GitHub). The list of all websites is also a Git repository.

Use this if you have multiple users in your organization and you want them to manage their own website. It is a much more lightweight solution than setting up a Git hosting platform with a Pages feature. It is an alternative to setting up Gitolite with a script to deploy sites pushed to it: this way your users can stay on the platform of their choice (e.g. GitHub) and you don't have to manage Gitolite accounts and keys.

Usage
-----

* Create a "control" repository somewhere (e.g. GitHub). This repository only needs a single file, `list.txt`, containing a list of folders with the corresponding repository URL, e.g. `~remi https://gitlab.com/remram44/personal-website`
* Put the script `sync.sh` on your server
* Edit the configuration at the top: set `CONTROL_REMOTE_URL` to the URL of the control repository, e.g. `https://github.com/remram44/static-sites-list`
* Install a web server (e.g. nginx or Apache2), make it serve the `WEB_ROOT` folder. Make sure that the folder is writable by the script and readable by the web server
* Run the script every day using cron
