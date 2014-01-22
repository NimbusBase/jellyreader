jellyreader
===========

![app screenshot](http://nimbusbase.github.io/jellyreader/app_screenshot.png)

RSS Reader or JellyReader is an app that stores all your articles on Google Drive and Dropbox! The data is completely self-hosted on your personal cloud, so it can never go down or go away.

##You can also clone this to run your own self-hosted version on github pages!

1. Fork this repository, the site should now be on a new gh-page
2. Make a single push to the repository, either by changing the readme or the index page (This is just because the github page won't build without a push after a fork)
3. Dropbox works right away in your new site, however, Google Drive needs an app key with the new domain and redirect url set. You can either just update Google Drive, or both at https://github.com/NimbusBase/jellyreader/blob/gh-pages/js/multi.coffee

  For Dropbox, go to: https://www.dropbox.com/developers/apps

  For Google, go to: https://cloud.google.com/console/project and create your own id and add your current github page URL as to both the domain and the URL redirect settings.

  This NimbusBase tutorial tells you where to change things: http://nimbusbase.com/learn.html

4. Everything should now run!

#license

JellyReader is licensed under the MIT license. However, NimbusBase is licensed seperately [http://nimbusbase.com/pricing.html]

<a href="http://nimbusbase.com/" target="_blank"><img src="http://nimbusbase.github.io/jellyreader/badge.png" /></a>
