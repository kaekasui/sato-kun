# Description:
#   リポジトリの一覧取得

module.exports = (robot) ->
  github = require("githubot")(robot)
  org_name = process.env.HUBOT_GITHUB_ORG
  url_api_base = "https://api.github.com"


  b64decode = (encodedStr) ->
    new Buffer(encodedStr, 'base64').toString()

  robot.respond /(.*)のURL.*/i, (msg) ->
    repo = msg.match[1]

    repos_url = "#{url_api_base}/orgs/#{org_name}/repos"
    # リポジトリ一覧を取得
    github.get repos_url, {}, (res) ->
      repos = res.map (n) ->
        n['name']
      if repos.includes(repo)
        msg.send "#{repo}でいいよね？"

        readme = "#{url_api_base}/repos/#{org_name}/#{repo}/readme"

        github.get readme, {}, (res) ->
          content = b64decode(res.content)

          production_url_match = content.match(/## 本番環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/)
          if production_url_match != null
            production_url = production_url_match[0].replace(/## 本番環境\n/, '')

          staging_url_match = content.match(/## ステージング環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/)
          if staging_url_match != null
            staging_url = staging_url_match[0].replace(/## ステージング環境\n/, '')

          if production_url == undefined && staging_url == undefined
            msg.send '設定されてないぽい'
          msg.send "```\nproduction: #{production_url}\nstaging: #{staging_url}\n```"
      else
        msg.send "#{repo}なんてないけど・・・"
