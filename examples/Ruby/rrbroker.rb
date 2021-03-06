# author: Oleg Sidorov <4pcbr> i4pcbr@gmail.com
# this code is licenced under the MIT/X11 licence.

require 'rubygems'
require 'ffi-rzmq'

context = ZMQ::Context.new
frontend = context.socket(ZMQ::XREP)
backend = context.socket(ZMQ::XREQ)

frontend.bind('tcp://*:5559')
backend.bind('tcp://*:5560')

poller = ZMQ::Poller.new
poller.register(frontend, ZMQ::POLLIN)
poller.register(backend, ZMQ::POLLIN)

loop do
  poller.poll(:blocking)
  poller.readables.each do |socket|
    if socket === frontend
      loop do
        message = socket.recv_string
        more = socket.more_parts?
        backend.send_string(message, more ? ZMQ::SNDMORE : 0)
        break unless more
      end
    elsif socket === backend
      loop do
        message = socket.recv_string
        more = socket.more_parts?
        frontend.send_string(message, more ? ZMQ::SNDMORE : 0)
        break unless more
      end
    end
  end
end
