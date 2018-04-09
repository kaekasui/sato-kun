# Description:
#   TrelloのTODO管理

# API_ACCESS_TOKEN
# API_URL
# TRELLO_BOARD_ID
# TRELLO_ANIME_BOARD_ID
# TRELLO_ACCOUNT_BOARD_ID
# TRELLO_DONE_LIST_ID
# TRELLO_ANIME_DONE_LIST_ID
# TRELLO_ACCOUNT_DONE_LIST_ID

request = require 'request'
cronJob = require('cron').CronJob

module.exports = (robot) ->
  access_token = process.env.API_ACCESS_TOKEN
  url = process.env.API_URL
  board_id = process.env.TRELLO_BOARD_ID
  anime_board_id = process.env.TRELLO_ANIME_BOARD_ID
  account_board_id = process.env.TRELLO_ACCOUNT_BOARD_ID
  done_list_id = process.env.TRELLO_DONE_LIST_ID
  anime_done_list_id = process.env.TRELLO_ANIME_DONE_LIST_ID
  account_done_list_id = process.env.TRELLO_ACCOUNT_DONE_LIST_ID

  setDoneCards = (board_id, list_id) ->
    uri = 'api/admin/tasks/all_done_tasks'
    request
      url: "#{url}#{uri}?board_id=#{board_id}&list_id=#{list_id}"
      method: 'POST'
      json: true
      headers:
        'Content-Type':'application/json'
        'Authorization': "Token token=#{access_token}"
      , (err, res, body) ->
        if err
          robot.send { room: "#reminder" }, "err: #{err}"
        else if res.statusCode == 201
          robot.send { room: "#reminder" }, "#{list_id}: 登録完了"
        else
          robot.send { room: "#reminder" }, "statusCode: #{res.statusCode}"

  deleteDoneCards = () ->
    uri = 'api/admin/tasks/all_done_tasks'
    request
      url: "#{url}#{uri}"
      method: 'DELETE'
      json: true
      headers:
        'Content-Type':'application/json'
        'Authorization': "Token token=#{access_token}"
      , (err, res, body) ->
        if err
          robot.send { room: "#reminder" }, "err: #{err}"

  setDiffCards = () ->
    uri = 'api/admin/tasks/done_tasks'
    request
      url: "#{url}#{uri}"
      method: 'GET'
      json: true
      headers:
        'Content-Type':'application/json'
        'Authorization': "Token token=#{access_token}"
      , (err, res, body) ->
        if err
          robot.send { room: "#reminder" }, "err: #{err}"
        else if res.statusCode == 200
          cards = body.tasks.map (card) ->
            card = '- ' + card.card_name
          if cards.length > 0
            list = '```\n' + cards.join('\n') + '```\n'
            robot.send { room: "#reminder" }, "たったらーん♪\n昨日は#{cards.length}件達成しました！"
            robot.send { room: "#reminder" }, list
          else
            robot.send { room: "#reminder" }, "昨日は何も達成できてません・・・"
        else
          robot.send { room: "#reminder" }, "statusCode: #{res.statusCode}"

  # 7時0分
  new cronJob(
    cronTime: "0 0 7 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      setDoneCards(board_id, done_list_id)
      setDoneCards(anime_board_id, anime_done_list_id)
      setDoneCards(account_board_id, account_done_list_id)
  )

  # 7時05分
  new cronJob(
    cronTime: "0 5 7 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      deleteDoneCards()
    )

  # 7時10分
  new cronJob(
    cronTime: "0 10 7 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      setDiffCards()
  )
