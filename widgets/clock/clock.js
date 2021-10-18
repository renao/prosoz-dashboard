/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
(function() {
  let seconds = undefined;
  let minutes = undefined;
  let hours = undefined;
  let intervalId = undefined;
  const Cls = (Dashing.Clock = class Clock extends Dashing.Widget {
    static initClass() {
      seconds = 0;
      minutes = 0;
      hours = 0;
      intervalId = 0;
    }

    formatTime(i) {
      if (i < 10) { return "0" + i; } else { return i; }
    }

    setDatetime(date) {
        const h = hours;
        const m = this.formatTime(minutes);
        const s = this.formatTime(seconds);
        this.set('time', h + ":" + m + ":" + s);
        const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
        return this.set('date', date.toLocaleDateString('de-DE', options));
      }

    onData(data) {
      if (data !== null) {
        clearInterval(intervalId);
        const date = new Date(data.currenttime);
        seconds = date.getSeconds();
        minutes = date.getMinutes();
        hours = date.getHours();

        return intervalId = setInterval((() => { 
          this.setDatetime(date);        
          seconds += 1;
          if (seconds === 60) {
            seconds = 0;
            minutes += 1;
          }
          if (minutes === 60) {
            minutes = 0;
            hours += 1;
          }
          if (hours === 24) {
            return hours = 0;
          }
        }
        ), 1000);
      }
    }
  });
  Cls.initClass();
  return Cls;
})();

      