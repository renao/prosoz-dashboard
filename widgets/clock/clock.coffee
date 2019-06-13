class Dashing.Clock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 500)

  startTime: =>
    today = new Date()
    h = today.getHours()
    m = today.getMinutes()
    s = today.getSeconds()
    m = @formatTime(m)
    s = @formatTime(s)
    @set('time', h + ":" + m + ":" + s)
    options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    @set('date', today.toLocaleDateString('de-DE', options))

  formatTime: (i) ->
    if i < 10 then "0" + i else i