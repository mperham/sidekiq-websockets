require 'reel'
require './fake_worker'

index_html = <<-HTML
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Sidekiq websocket example</title>
    <style>
      body {
        font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
        font-weight: 300;
        text-align: center;
      }

      #content {
        width: 800px;
        margin: 0 auto;
        background: #EEEEEE;
        padding: 1em;
      }
    </style>
  </head>
  <script>
    var SocketKlass = "MozWebSocket" in window ? MozWebSocket : WebSocket;
    var ws = new SocketKlass('ws://' + window.location.host + '/batch_status/XXXXX.json');
    ws.onmessage = function(msg){
      document.getElementById('current-data').innerHTML += msg.data;
    }
  </script>
  <body>
    <div id="content">
      <h1>Real Time Processing Example</h1>
      <div>Batch Status: <span id="current-data"></span></div>
    </div>
  </body>
  </html>
HTML

Sidekiq.configure_client do |config|
  require 'celluloid/redis'
  # The celluloid-redis driver is required to handle
  # multiple websocket requests concurrently.
  config.redis = { :driver => :celluloid }
end

Reel::Server.supervise("0.0.0.0", 3000) do |connection|
  while request = connection.request
    case request
    when Reel::Request
      puts "Client requested: #{request.method} #{request.url}"
      batch = Sidekiq::Batch.new
      batch.jobs do
        FakeWorker.perform_async
        FakeWorker.perform_async
        FakeWorker.perform_async
      end
      request.respond(:ok, index_html.gsub(/XXXXX/, batch.bid))
    when Reel::WebSocket
      puts "Client made a WebSocket request to: #{request.url}"
      request.url =~ /\A\/batch_status\/([0-9a-f]{16})\.json\z/
      bid = $1
      Sidekiq.redis do |conn|
        # this is a blocking loop, we need to use celluloid-redis
        # so that the web server can respond to other requests while
        # blocking here.
        conn.psubscribe("batch-#{bid}") do |on|
          on.pmessage do |pattern, channel, msg|
            # channel = 'batch-123456789'
            # msg = '-', '+' or '!'
            begin
              request << msg
              if msg == '!'
                conn.punsubscribe
                request.close
              end
            rescue => ex
              puts ex.message
              conn.punsubscribe
              request.close
            end
          end
        end
      end

    end
  end
end


puts "Listening on port 3000"
sleep
