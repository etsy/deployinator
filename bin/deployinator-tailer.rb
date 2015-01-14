#!/bin/env ruby

require "deployinator"
require "deployinator/base"
require "deployinator/helpers"
require 'deployinator/stack-tail'
require 'deployinator/helpers/stack-tail'

# Note: If you change the protocol of how this communicates with the front end,
# please also update the version located in helpers/stack-tail.rb
EM.run do
  @@tailers = Hash.new
  @@channels = Hash.new
  @@channels_count = Hash.new

  # reload the list of stacks from Deployinator without affecting
  # existing channels. does not remove stacks that no longer exist`
  def refresh_stacks
    Deployinator.get_stacks.each do |stack|
      unless @@channels.key?(stack)
        @@channels[stack] = EM::Channel.new
        @@channels_count[stack] = 0
      end
    end
  end

  # refresh the available stacks when we receive a HUP signal
  Signal.trap('HUP')  { refresh_stacks }
  refresh_stacks

  EM::WebSocket.start(:host => "0.0.0.0", :port => Deployinator.stack_tailer_port) do |ws|

    # This attempts to attach a tailer to the stack symlink. If it doesn't
    # exist yet it will attempt next tick of the EventMachine
    def attach_tailer(stack)
      if @@channels.key?(stack) 
        tailer = Tailer.stack_tail(stack, @@channels[stack], @@channels_count[stack])
        if tailer
          @@tailers[stack] = tailer
        else
          EM.next_tick do
            attach_tailer(stack)
          end
        end
      end
    end

    ws.onopen do |handshake|
      session_id = false
      stack = false
      ws.send(Deployinator::Helpers::StackTailHelpers::get_stack_tail_version())

      ws.onclose do
        if stack && @@channels.key?(stack)
          @@channels[stack].unsubscribe(session_id)
          @@channels_count[stack] -= 1
          if @@channels_count[stack] == 0
            @@tailers[stack].close
            @@tailers.delete(stack)
          end
        end
      end

      ws.onmessage do |msg|
        stack = msg
        if @@channels.key?(stack)
          unless @@tailers.key?(stack)
            attach_tailer(stack)
          end
          @@channels_count[stack] += 1
          session_id = @@channels[stack].subscribe do |data|
            ws.send(data)
          end
        end
      end
    end
  end
end
