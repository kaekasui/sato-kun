# Description:
#   CoffeeScriptによるhubot作成例

module.exports = (robot) ->
  robot.hear /(sushi|すし|スシ|寿司)/i, (msg) ->
    msg.send 'スシが食べたい。'
