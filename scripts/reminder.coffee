cronJob = require('cron').CronJob

module.exports = (robot) ->
  date = new Date()
  week_day = date.getDay()
  day = 1
  if [0, 6].includes(week_day)
    day = (week_day == 0) ? 2 : 3
    week_day = 1

  cronjob = new cronJob(
    cronTime: "0 0 9 " + day +" * " + week_day
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#reminder" }, "請求書出した？"
  )
