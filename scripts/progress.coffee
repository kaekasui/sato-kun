# Description:
#   TrelloのTODO管理

# TRELLO_API_KEY
# TRELLO_API_TOKEN
# TRELLO_TODAY_LIST_ID
# TRELLO_TOMORROW_LIST_ID
# TRELLO_ACCOUNT_LIST_ID
# TRELLO_ANIME_LIST_ID

request = require 'request'
cronJob = require('cron').CronJob

module.exports = (robot) ->
  url = 'https://trello.com/1/'
  key = process.env.TRELLO_API_KEY
  token = process.env.TRELLO_API_TOKEN
  today_list_id = process.env.TRELLO_TODAY_LIST_ID
  tomorrow_list_id = process.env.TRELLO_TOMORROW_LIST_ID
  account_list_id = process.env.TRELLO_ACCOUNT_LIST_ID
  anime_list_id = process.env.TRELLO_ANIME_LIST_ID

  getCards = (pre_comment, list_id) ->
    cards_url = url + 'lists/' + list_id + '/cards'
    get_cards_url = cards_url + '?fields=name&key=' + key + '&token=' + token
    request { url: get_cards_url }, (error, response, body) ->
      if !error
        json = JSON.parse body
        cards = json.map (card) ->
          card = '- ' + card.name
        comment = '```\n' + cards.join('\n') + '```\n'
        robot.send { room: "#reminder" }, pre_comment + comment
      else
        robot.send { room: "#reminder" }, JSON.stringify(error)

  # 13時
  new cronJob(
    cronTime: "0 0 12 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      pre_comment = '進捗どうですか？\n'
      getCards(pre_comment, today_list_id)
  )

  # 14時
  new cronJob(
    cronTime: "0 0 14 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      pre_comment = 'いかがですか？\n'
      getCards(pre_comment, account_list_id)
      getCards(pre_comment, anime_list_id)
  )

  # 18時
  new cronJob(
    cronTime: "0 0 18 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      pre_comment = '進捗どうですか？\n'
      getCards(pre_comment, today_list_id)
      pre_comment = '明日できますか？\n'
      getCards(pre_comment, tomorrow_list_id)
  )
