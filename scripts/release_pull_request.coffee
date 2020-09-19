# Description:
#   自動リリース機能。masterからproductionにマージするPRを自動生成する。
#   日曜日のAM9:00とAM9:10に実行。
#   また、手動で実行も可能。

# HUBOT_GITHUB_TOKEN
# HUBOT_GITHUB_USER
# HUBOT_GITHUB_ORG

module.exports = (robot) ->
  cronJob = require('cron').CronJob
  github = require("githubot")(robot)
  orgName = process.env.HUBOT_GITHUB_ORG
  userName = 'kaekasui'
  urlApiBase = "https://api.github.com"

  productionRegex = /## 本番環境\n*- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/
  stagingRegex = /## ステージング環境\n*- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/

  b64decode = (encodedStr) ->
    new Buffer(encodedStr, 'base64').toString()

  getUrlInfo = (content) ->
    productionUrlMatch = content.match(productionRegex)
    productionUrl = ''
    if productionUrlMatch != null
      productionUrl = 'production: '
      console.log(productionUrlMatch[0])
      productionUrl += productionUrlMatch[0].replace(/## 本番環境\n/, '')
    stagingUrlMatch = content.match(stagingRegex)
    stagingUrl = ''
    if stagingUrlMatch != null
      stagingUrl = 'staging: '
      stagingUrl = stagingUrlMatch[0].replace(/## ステージング環境\n/, '')
    "\n#{productionUrl}\n#{stagingUrl}\n"

  getMergePRList = (commits) ->
    body = ''
    for commit in commits
      unless commit.commit.message.match(/Merge pull request/)
        continue
      replacedComment = commit.commit.message.replace(/\n\n/g, ' ')
        .replace(/Merge pull request /, '')
        .replace(new RegExp("from #{orgName}\/[A-Za-z0-9_-]*"), '')
      body += "- #{replacedComment}\n"
    body

  createPullRequest = (msg, params, readmeUrl, pullsUrl, tagUrl) ->
    github.post pullsUrl, params, (response) ->
      commitsUrl = "#{response.commits_url}?per_page=100"
      github.get commitsUrl, (commits) ->
        prBody = "リリース用のPRを作成しました。\n"
        prBody += getMergePRList(commits)
        prBody += "\n"
        prBody += "URL:\n"

        github.get readmeUrl, {}, (res) ->
          content = b64decode(res.content)
          prBody += getUrlInfo(content)
          update_data = { body: prBody }
          github.patch response.url, update_data, (update_response) ->
            msg.send update_response.html_url
            msg.send 'PR作成した！マージよろしく！'

  updatePullRequest = (msg, readmeUrl, pullUrl) ->
    github.get pullUrl, (response) ->
      commitsUrl = "#{response.commits_url}?per_page=100"
      github.get commitsUrl, (commits) ->
        prBody = "リリース用のPRを更新しました。\n"
        prBody += getMergePRList(commits)
        prBody += "\n"
        prBody += "URL:\n"

        github.get readmeUrl, {}, (res) ->
          content = b64decode(res.content)
          prBody += getUrlInfo(content)
          update_data = { body: prBody }
          github.patch response.url, update_data, (update_response) ->
            msg.send "更新したー"
            msg.send update_response.html_url

  robot.respond /anime-musicをリリースし.*/i, (msg) ->
    releaseReadiness('orgs', 'anime-music')
  robot.respond /cryuni_simをリリースし.*/i, (msg) ->
    releaseReadiness('users', 'cryuni_sim')
  robot.respond /account-book-pigをリリースし.*/i, (msg) ->
    releaseReadiness('orgs', 'account-book-pig')
  robot.respond /pig-bookをリリースし.*/i, (msg) ->
    releaseReadiness('orgs', 'pig-book')

  new cronJob(
    cronTime: "0 0 9 * * 0"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      repo = 'anime-music'
      response.send "#{repo}: 定期リリースを開始します"
      releaseReadiness('orgs', repo)
  )

  new cronJob(
    cronTime: "0 5 9 * * 0"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      repo = 'account-book-pig'
      response.send "#{repo}: 定期リリースを開始します"
      releaseReadiness('orgs', repo)
  )

  new cronJob(
    cronTime: "0 10 9 * * 0"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      repo = 'cryuni_sim'
      response.send "#{repo}: 定期リリースを開始します"
      releaseReadiness('users', repo)
  )

  new cronJob(
    cronTime: "0 15 9 * * 0"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      repo = 'pig-book'
      response.send "#{repo}: 定期リリースを開始します"
      releaseReadiness('users', repo)
  )

  releaseReadiness = (target, repo) ->
    msgInfo =
      room: '#dev',
      user: {id: -1, name: '#dev'},
      text: 'NONE',
      done: false
    msg = new robot.Response(robot, msgInfo, [])
    reposUrl =
      switch target
        when 'orgs' then "#{urlApiBase}/orgs/#{orgName}/repos"
        when 'users' then "#{urlApiBase}/users/#{userName}/repos"

    # リポジトリ一覧を取得
    github.get reposUrl, {}, (res) ->
      repos = res.map (n) ->
        n['name']
      if repos.includes(repo)
        msg.send "#{repo}でいいよね？"

        params = {
          "title": "#{new Date().toLocaleDateString()} リリース"
          "body": 'body is a required item.'
          "head": 'master'
          "base": 'production'
        }
        # URL
        repoUrl =
          switch target
            when 'orgs' then "#{urlApiBase}/repos/#{orgName}/#{repo}"
            when 'users' then "#{urlApiBase}/repos/#{userName}/#{repo}"
        readmeUrl = "#{repoUrl}/readme"
        pullsUrl = "#{repoUrl}/pulls"
        tagUrl = "#{repoUrl}/git/refs/tags"

        # プルリクエストを確認する
        github.get pullsUrl, params, (response) ->
          if response.length > 0
            msg.send "もうある、更新しとく。"
            pullUrl = "#{pullsUrl}/#{response[0].number}"
            # プルリクエストを更新
            updatePullRequest(msg, readmeUrl, pullUrl)
          else
            msg.send 'PR作成する・・・'
            # プルリクエストを作成
            createPullRequest(msg, params, readmeUrl, pullsUrl, tagUrl)

        github.handleErrors (response) ->
          if response.body.indexOf("No commits") > -1
            msg.send 'あれ？差分ないし、特に作る必要なさそう・・・（仕事しろ'
          else
            msg.send 'handle errors response body'
            msg.send "```\n#{response.body.toString()}\n```"
      else
        msg.send "#{repo}なんてないけど・・・"
