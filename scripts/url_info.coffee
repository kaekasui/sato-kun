# Description:
#   リポジトリの一覧取得

module.exports = (robot) ->
  github = require("githubot")(robot)
  user_name = 'kaekasui'
  org_name = process.env.HUBOT_GITHUB_ORG
  url_api_base = "https://api.github.com"

  b64decode = (encodedStr) ->
    new Buffer(encodedStr, 'base64').toString()

  getReadme = (msg, repo, target, repos_url) ->
    github.get repos_url, {}, (res) ->
      repos = res.map (n) ->
        n['name']
      if repos.includes(repo)
        msg.send "#{repo}でいいよね？"
        readme =
          if target == 'orgs'
            "#{url_api_base}/repos/#{org_name}/#{repo}/readme"
          else if target == 'users'
            "#{url_api_base}/repos/#{user_name}/#{repo}/readme"
        msg.send "orgs os users #{readme}"

        github.get readme, {}, (res) ->
          content = b64decode(res.content)

          regex = /## 本番環境\n*- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/
          production_url_match = content.match(regex)
          production_url = ''
          if production_url_match != null
            production_url = "production: "
            production_url += production_url_match[0].replace(/## 本番環境\n/, '')

          regex = /## ステージング環境\n*- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/
          staging_url_match = content.match(regex)
          staging_url = ''
          if staging_url_match != null
            staging_url = "staging: "
            staging_url += staging_url_match[0].replace(/## ステージング環境\n/, '')

          if production_url == '' && staging_url == ''
            msg.send '設定されてないぽい'
          msg.send "```\n#{production_url}\n#{staging_url}\n```"

  findRepository = (msg, repo) ->
    org_repos_url = "#{url_api_base}/orgs/#{org_name}/repos"
    getReadme(msg, repo, 'orgs', org_repos_url)

    user_repos_url = "#{url_api_base}/users/#{user_name}/repos"
    getReadme(msg, repo, 'users', user_repos_url)

  robot.respond /(.*)のURL.*/i, (msg) ->
    repo = msg.match[1]

    findRepository(msg, repo)
    #repos_url = "#{url_api_base}/orgs/#{org_name}/repos"
    # リポジトリ一覧を取得
    #github.get repos_url, {}, (res) ->
      #repos = res.map (n) ->
      #  n['name']
      #if repos.includes(repo)
        #msg.send "#{repo}でいいよね？"

        #readme = "#{url_api_base}/repos/#{org_name}/#{repo}/readme"

        #msg.send "readme: #{readme}"
        #github.get readme, {}, (res) ->
        #  content = b64decode(res.content)

        #  regex = /## 本番環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/
        #  production_url_match = content.match(regex)
        #  if production_url_match != null
        #    production_url = "production: "
        #    production_url += production_url_match[0].replace(/## 本番環境\n/, '')

        #  regex = /## ステージング環境\n- https?:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/
        #  staging_url_match = content.match(regex)
        #  if staging_url_match != null
        #    staging_url = "stagins: "
        #    staging_url += staging_url_match[0].replace(/## ステージング環境\n/, '')

        #  if production_url == undefined && staging_url == undefined
        #    msg.send '設定されてないぽい'
        #  msg.send "```\n#{production_url}\n#{staging_url}\n```"
      #else
      #  msg.send "#{repo}なんてないけど・・・"
