require 'httparty'
require 'json'
require 'date'

SCHEDULER.every '15m', :first_in => 0 do
    send_event('UpdateCurrentServerTime', {currenttime: DateTime.now})
end