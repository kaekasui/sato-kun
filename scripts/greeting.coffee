cronJob = require('cron').CronJob

module.exports = (robot) ->
  new cronJob(
    cronTime: "0 0 9 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#reminder" }, "おはよー"
  )

  now = new Date()
  hour = now.getHours()

  new cronJob(
    cronTime: "0 0 12,18,22 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#reminder" }, hour + "時ですよー"
  )
