cronJob = require('cron').CronJob

module.exports = (robot) ->
  # 月初
  new cronJob(
    cronTime: "0 0 9 1 * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#reminder" }, "請求書出した？"
  )
