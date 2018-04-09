# Description:
#   朝にあいさつをするBot

cronJob = require('cron').CronJob

module.exports = (robot) ->
  new cronJob(
    cronTime: "0 0 9 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#reminder" }, "おはよー"
  )
