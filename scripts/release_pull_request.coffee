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
  b64decode = (encodedStr) ->
    new Buffer(encodedStr, 'base64').toString()

  productionRegex = /## 本番環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/
  stagingRegex = /## ステージング環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/

  readmeOrgsUrl = "#{urlApiBase}/repos/#{orgName}/#{repo}/readme"
  readmeUsersUrl = "#{urlApiBase}/repos/#{userName}/#{repo}/readme"
  tagOrgsUrl = "#{urlApiBase}/repos/#{orgName}/#{repo}/git/refs/tags"
  tagUsersUrl = "#{urlApiBase}/repos/#{userName}/#{repo}/git/refs/tags"
  pullsOrgsUrl = "#{urlApiBase}/repos/#{orgName}/#{repo}/pulls"
  pullsUsersUrl = "#{urlApiBase}/repos/#{userName}/#{repo}/pulls"

  createPullRequest = (url, params, msg, repo, target) ->
    github.post url, params, (response) ->
      commits_url = "#{response.commits_url}?per_page=100"
      github.get commits_url, (commits) ->
        prBody = "リリース用のPRを作成しました。\n"
        for commit in commits
          unless commit.commit.message.match(/Merge pull request/)
            continue
          replacedComment = commit.commit.message.replace(/\n\n/g, ' ')
            .replace(/Merge pull request /, '')
            .replace(new RegExp("from #{orgName}\/[A-Za-z0-9_-]*"), '')
          prBody += "- #{replacedComment}\n"
        prBody += "\n"
        prBody += "URL:\n"

        readme =
          if target == 'orgs' then readmeOrgsUrl
          else if target == 'users' then readmeUsersUrl
        github.get readme, {}, (res) ->
          content = b64decode(res.content)

          productionUrlMatch = content.match(productionRegex)
          if productionUrlMatch != null
            productionUrl = productionUrlMatch[0].replace(/## 本番環境\n- /, '')

          staging_url_match = content.match(stagingRegex)
          if staging_url_match != null
            staging_url = staging_url_match[0].replace(/## ステージング環境\n- /, '')

          if productionUrl != undefined
            prBody += "- production: #{productionUrl}\n"
          if staging_url != undefined
            prBody += "- master: #{staging_url}\n"

          update_data = { body: prBody }
          github.patch response.url, update_data, (update_response) ->
            get_tags_url =
              switch target
                when 'orgs' then tagOrgsUrl
                when 'users' then tagUsersUrl
            github.get get_tags_url, (tags_response) ->
              msg.send 'PR作成した！マージよろしく！あと、tag生成もよろしく！'
              msg.send update_response.html_url
              msg.send 'ちなみに現在のタグは・・・'
              tag_names = tags_response.map (tags) -> tags.ref
              msg.send "#{tag_names.join()}"

  updatePullRequest = (msg, repo, target, number) ->
    url =
      switch target
        when 'orgs' then "#{pullsOrgsUrl}/#{number}"
        when 'users' then "#{pullsUsersUrl}/#{number}"

    github.get url, (response) ->
      commits_url = "#{response.commits_url}?per_page=100"
      github.get commits_url, (commits) ->
        prBody = "リリース用のPRを作成しました。\n"
        for commit in commits
          unless commit.commit.message.match(/Merge pull request/)
            continue
          replacedComment = commit.commit.message.replace(/\n\n/g, ' ')
            .replace(/Merge pull request /, '')
            replace(new RegExp("from #{orgName}\/[A-Za-z0-9_-]*"), '')
          prBody += "- #{replacedComment}\n"
        prBody += "\n"
        prBody += "URL:\n"

        readme =
          if target == 'orgs' then readmeOrgsUrl
          else if target == 'users' then readmeUsersUrl
        github.get readme, {}, (res) ->
          content = b64decode(res.content)

          productionUrlMatch = content.match(productionRegex)
          if productionUrlMatch != null
            productionUrl = productionUrlMatch[0].replace(/## 本番環境\n- /, '')

          staging_url_match = content.match(stagingRegex)
          if staging_url_match != null
            staging_url = staging_url_match[0].replace(/## ステージング環境\n- /, '')

          if productionUrl != undefined
            prBody += "- production: #{productionUrl}\n"
          if staging_url != undefined
            prBody += "- master: #{staging_url}\n"

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

  releaseReadiness = (target, repo) ->
    msgInfo =
      room: '#dev',
      user: {id: -1, name: '#dev'},
      text: 'NONE',
      done: false
    msg = new robot.Response(robot, msgInfo, [])
    repos_url =
      switch target
        when 'orgs' then "#{urlApiBase}/orgs/#{orgName}/repos"
        when 'users' then "#{urlApiBase}/users/#{userName}/repos"
    create_pull_url =
      switch target
        when 'orgs' then pullsOrgsUrl
        when 'users' then pullsUsersUrl

    # リポジトリ一覧を取得
    github.get repos_url, {}, (res) ->
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
        # プルリクエストを確認する
        github.get create_pull_url, params, (response) ->
          if response.length > 0
            msg.send "もうある、更新しとく。"
            # プルリクエストを更新
            updatePullRequest(msg, repo, target, response[0].number)
          else
            msg.send 'PR作成する・・・'
            # プルリクエストを作成
            createPullRequest(create_pull_url, params, msg, repo, target)

        github.handleErrors (response) ->
          if response.body.indexOf("No commits") > -1
            msg.send 'あれ？差分ないし、特に作る必要なさそう・・・（仕事しろ'
          else
            msg.send 'handle errors response body'
            msg.send "```\n#{response.body.toString()}\n```"
      else
        msg.send "#{repo}なんてないけど・・・"
