cronJob = require('cron').CronJob

module.exports = (robot) ->
  new cronJob(
    cronTime: "0 0 9 * * 6"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      robot.send { room: "#dev" }, "おはようございます。"
      robot.send { room: "#dev" }, "@sato-kun anime-musicをリリースします。（土曜日定期リリース）"
  )
