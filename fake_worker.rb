require 'sidekiq-pro'

class FakeWorker
  include Sidekiq::Worker

  def perform
    sleep 5
  end
end
