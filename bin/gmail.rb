#!/usr/bin/env ruby
# A small script that checks unseen messages on gmail, used in polybar
# Copyright © 2018 Paul Sonkoly

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'yaml'
require 'gmail'
require 'libnotify'

LOGIN_CONFIG = File.join(ENV['HOME'], 'gmail.yaml')

$login = File.open(LOGIN_CONFIG, 'r') { |io| YAML.load(io.read) }

def connect
  Gmail.connect($login['username'], $login['password'])
end

def loop_with_delay
  loop do
    yield
    sleep 90
  end
end

def with_connection
  gmail = nil
  loop_with_delay do
    if gmail && gmail.logged_in?
      yield(gmail)
    else
      gmail = connect
      redo if gmail.logged_in?
    end
  end
end

with_connection do |gmail|
  new_count = gmail.inbox.unseen.count
  if @count && @count < new_count
    Libnotify.new do |notify|
      notify.summary = 'Email'
      notify.body = "#{new_count - @count} new unseen"
    end.show!
  end
  if @count != new_count
    puts new_count
    STDOUT.flush
    @count = new_count
  end
end
