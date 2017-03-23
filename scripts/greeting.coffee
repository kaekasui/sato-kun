cronJob = require('cron').CronJob

module.exports = (robot) ->
  new cronJob(
    cronTime: "0 0 9 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#reminder" }, "おはよー"
  )

  now_utc = new Date()
  now_jst = now_utc.toLocaleString()

  new cronJob(
    cronTime: "0 0 12,18,22 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#reminder" }, now_jst + "ですよー"
  )
