module Async

  # This will be called by a worker when a job needs to be processed
  def perform(id, method, *args)
    if id
      begin
        self.class.find(id).send(method, *args)
      rescue ActiveRecord::RecordNotFound
        # If the record was deleted after the job was created, swallow it
      end
    else
      self.class.send(method, *args)
    end
  end

  def async(method, *args)
    Sidekiq::Client.enqueue(self.class, id, method, *args)
  end

end

