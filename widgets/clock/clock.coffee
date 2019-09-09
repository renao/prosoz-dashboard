class Dashing.Clock extends Dashing.Widget
  seconds = 0
  minutes = 0
  hours = 0
  intervalId = 0

  formatTime: (i) ->
    if i < 10 then "0" + i else i

  setDatetime: (date) ->
      h = hours
      m = @formatTime(minutes)
      s = @formatTime(seconds)
      @set('time', h + ":" + m + ":" + s)
      options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
      @set('date', date.toLocaleDateString('de-DE', options))

  onData: (data) ->
    if (data != null)
      clearInterval(intervalId)
      date = new Date(data.currenttime)
      seconds = date.getSeconds()
      minutes = date.getMinutes()
      hours = date.getHours()

      intervalId = setInterval (=> 
        @setDatetime(date)        
        seconds += 1
        if seconds == 60
          seconds = 0
          minutes += 1
        if minutes == 60
          minutes = 0
          hours += 1
        if hours == 24
          hours = 0
      ), 1000

      