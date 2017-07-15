# HUBOT_GITHUB_TOKEN
# HUBOT_GITHUB_USER
# HUBOT_GITHUB_ORG

module.exports = (robot) ->
  github = require("githubot")(robot)
  org_name = process.env.HUBOT_GITHUB_ORG
  url_api_base = "https://api.github.com"
  b64decode = (encodedStr) ->
    new Buffer(encodedStr, 'base64').toString()

  createPullRequest = (url, params, msg, repo) ->
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

        readme = "#{url_api_base}/repos/#{org_name}/#{repo}/readme"
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
            msg.send 'PR作成した！マージよろしく！'
            msg.send update_response.html_url

  updatePullRequest = (url, msg, repo) ->
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

        readme = "#{url_api_base}/repos/#{org_name}/#{repo}/readme"
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

  robot.respond /(.*)をリリースし.*/i, (msg) ->
    releaseReadiness()

  releaseReadiness = (mgs) ->
    repo = msg.match[1]

    repos_url = "#{url_api_base}/orgs/#{org_name}/repos"
    # リポジトリ一覧を取得
    github.get repos_url, {}, (res) ->
      repos = res.map (n) ->
        n['name']
      if repos.includes(repo)
        msg.send "#{repo}でいいよね？"

        pulls_url = "#{url_api_base}/repos/#{org_name}/#{repo}/pulls"
        params = {
          "title": "#{new Date().toLocaleDateString()} リリース"
          "head": 'master'
          "base": 'production'
        }
        # プルリクエストを確認する
        github.get pulls_url, params, (response) ->
          if response.length > 0
            msg.send "もうある、更新しとく。"
            pull_url = "#{url_api_base}/repos/#{org_name}/#{repo}/pulls/#{response[0].number}"
            # プルリクエストを更新
            updatePullRequest(pull_url, msg, repo)
          else
            msg.send 'PR作成する・・・'
            # プルリクエストを作成
            createPullRequest(pulls_url, params, msg, repo)

        github.handleErrors (response) ->
          if response.body.indexOf("No commits") > -1
            msg.send 'あれ？差分ないし、特に作る必要なさそう・・・（仕事しろ'
      else
        msg.send "#{repo}なんてないけど・・・"
