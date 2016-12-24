cronJob = require('cron').CronJob

module.exports = (robot) ->
  cronjob = new cronJob(
    cronTime: "0 0 9 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#random" }, "おはよー"
  )
