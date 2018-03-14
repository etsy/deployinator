# -*- coding: utf-8 -*-
require "em-websocket"
require "eventmachine-tail"

module Tailer
  # Extends FileTail to push data tailed to an EM::Channel. All open websockets
  # subscribe to a channel for the request stack and this pushes the data to
  # all of them at once.
  class StackTail < EventMachine::FileTail
    def initialize(filename, channel, startpos=-1)
      super(filename, startpos)
      @channel = channel
      @buffer = BufferedTokenizer.new
    end

    # This method is called whenever FileTail receives an inotify event for
    # the tailed file. It breaks up the data per line and pushes a line at a
    # time. This is to prevent the last javascript line from being broken up
    # over 2 pushes thus breaking the eval on the front end.
    def receive_data(data)
      # replace non UTF-8 characters with ?
      data.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '�')
      @buffer.extract(data).each do |line|
        @channel.push line
      end
    end
  end

  # Checks if stack log symlink exists and creates Tailer for it
  def self.stack_tail(stack, channel, channel_count)
    if Deployinator.get_visible_stacks.include?(stack)
      filename = "#{Deployinator::Helpers::RUN_LOG_PATH}current-#{stack}"
      start_pos = (channel_count == 0) ? 0 : -1
      File.exists?(filename) ? StackTail.new(filename, channel, start_pos) : false
    end
  end
end
