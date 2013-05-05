sidekiq-websockets
==================

This repo shows you how to use websockets to watch job processing in
real-time with [Sidekiq Pro](http://sidekiq.org/pro) in your web browser.
Sidekiq Pro's Batch feature is what allows this monitoring to work.

Install
========

Edit the Gemfile to include your Sidekiq Pro access configuration.  Run `bundle` to install the necessary gems.

This assumes you have Redis running on localhost:6379.
In one terminal, run `bundle exec ruby http.rb` to start the web server.
In another terminal, run `bundle exec sidekiq -c 1`

Hit `http://localhost:3000`.  Loading the page will kick off a batch of
three jobs; the javascript on the page will open a websocket to pull
status updates for that batch.
