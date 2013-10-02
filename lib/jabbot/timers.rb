module Jabbot
  module Timers

    # Public: Add a periodic event
    #
    # period  - The time between calls to blk
    # blk     - The block to be called
    #
    # Returns the handler.
    def add_periodic(period, &blk)
      new_timer = {:period => period, :block => blk}
      if @timers.nil?
        @timers = [new_timer]
      else
        @timers << new_timer
      end
    end

    def schedule_periodic_events
      if @timers
        @timers.each do |timer|
          EventMachine.add_periodic_timer(timer[:period], timer[:block])
        end
      end
    end

  end
end
