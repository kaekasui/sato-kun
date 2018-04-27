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
  org_name = process.env.HUBOT_GITHUB_ORG
  user_name = 'kaekasui'
  url_api_base = "https://api.github.com"
  b64decode = (encodedStr) ->
    new Buffer(encodedStr, 'base64').toString()

  createPullRequest = (url, params, msg, repo, target) ->
    github.post url, params, (response) ->
      commits_url = "#{response.commits_url}?per_page=100"
      github.get commits_url, (commits) ->
        pr_body = "リリース用のPRを作成しました。\n"
        for commit in commits
          unless commit.commit.message.match(/Merge pull request/)
            continue
          pr_body += "- #{commit.commit.message.replace(/\n\n/g, ' ').replace(/Merge pull request /, '').replace(new RegExp("from #{org_name}\/[A-Za-z0-9_-]*"), '')}\n"
        pr_body += "\n"
        pr_body += "URL:\n"

        readme =
          if target == 'orgs'
            "#{url_api_base}/repos/#{org_name}/#{repo}/readme"
          else if target == 'users'
            "#{url_api_base}/repos/#{user_name}/#{repo}/readme"
        github.get readme, {}, (res) ->
          content = b64decode(res.content)

          production_url_match = content.match(/## 本番環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/)
          if production_url_match != null
            production_url = production_url_match[0].replace(/## 本番環境\n- /, '')

          staging_url_match = content.match(/## ステージング環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/)
          if staging_url_match != null
            staging_url = staging_url_match[0].replace(/## ステージング環境\n- /, '')

          if production_url != undefined
            pr_body += "- production: #{production_url}\n"
          if staging_url != undefined
            pr_body += "- master: #{staging_url}\n"

          update_data = { body: pr_body }
          github.patch response.url, update_data, (update_response) ->
            get_tags_url =
              switch target
                when 'orgs' then "#{url_api_base}/repos/#{org_name}/#{repo}/git/refs/tags"
                when 'users' then "#{url_api_base}/repos/#{user_name}/#{repo}/git/refs/tags"
            github.get get_tags_url, (tags_response) ->
              msg.send 'PR作成した！マージよろしく！あと、tag生成もよろしく！'
              msg.send update_response.html_url
              msg.send 'ちなみに現在のタグは・・・'
              tag_names = tags_response.map (tags) -> tags.ref
              msg.send "#{tag_names.join()}"

  updatePullRequest = (msg, repo, target, number) ->
    url =
      switch target
        when 'orgs' then "#{url_api_base}/repos/#{org_name}/#{repo}/pulls/#{number}"
        when 'users' then "#{url_api_base}/repos/#{user_name}/#{repo}/pulls/#{number}"

    github.get url, (response) ->
      commits_url = "#{response.commits_url}?per_page=100"
      github.get commits_url, (commits) ->
        pr_body = "リリース用のPRを作成しました。\n"
        for commit in commits
          unless commit.commit.message.match(/Merge pull request/)
            continue
          pr_body += "- #{commit.commit.message.replace(/\n\n/g, ' ').replace(/Merge pull request /, '').replace(new RegExp("from #{org_name}\/[A-Za-z0-9_-]*"), '')}\n"
        pr_body += "\n"
        pr_body += "URL:\n"

        readme =
          if target == 'orgs'
            "#{url_api_base}/repos/#{org_name}/#{repo}/readme"
          else if target == 'users'
            "#{url_api_base}/repos/#{user_name}/#{repo}/readme"
        github.get readme, {}, (res) ->
          content = b64decode(res.content)

          production_url_match = content.match(/## 本番環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/)
          if production_url_match != null
            production_url = production_url_match[0].replace(/## 本番環境\n- /, '')

          staging_url_match = content.match(/## ステージング環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/)
          if staging_url_match != null
            staging_url = staging_url_match[0].replace(/## ステージング環境\n- /, '')

          if production_url != undefined
            pr_body += "- production: #{production_url}\n"
          if staging_url != undefined
            pr_body += "- master: #{staging_url}\n"

          update_data = { body: pr_body }
          github.patch response.url, update_data, (update_response) ->
            msg.send "更新したー"
            msg.send update_response.html_url

  robot.respond /anime-musicをリリースし.*/i, (msg) ->
    releaseReadiness('orgs', 'anime-music')
  robot.respond /cryuni_simをリリースし.*/i, (msg) ->
    releaseReadiness('users', 'cryuni_sim')

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
    cronTime: "0 10 9 * * 0"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      repo = 'cryuni_sim'
      response.send "#{repo}: 定期リリースを開始します"
      releaseReadiness('users', repo)
  )

  releaseReadiness = (target, repo) ->
    msg = new robot.Response(robot, { room: '#dev', user: {id: -1, name: '#dev'}, text: 'NONE', done: false }, [])
    repos_url =
      switch target
        when 'orgs' then "#{url_api_base}/orgs/#{org_name}/repos"
        when 'users' then "#{url_api_base}/users/#{user_name}/repos"
    create_pull_url =
      switch target
        when 'orgs' then "#{url_api_base}/repos/#{org_name}/#{repo}/pulls"
        when 'users' then "#{url_api_base}/repos/#{user_name}/#{repo}/pulls"

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
          msg.send 'handle errors response body'
          msg.send '```'
          msg.send "#{response.body.toString()}"
          msg.send '```'
          if response.body.indexOf("No commits") > -1
            msg.send 'あれ？差分ないし、特に作る必要なさそう・・・（仕事しろ'
      else
        msg.send "#{repo}なんてないけど・・・"
