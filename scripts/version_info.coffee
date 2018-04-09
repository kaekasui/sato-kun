# Description:
#   バージョンを取得

module.exports = (robot) ->
  github = require("githubot")(robot)
  org_name = process.env.HUBOT_GITHUB_ORG
  url_api_base = "https://api.github.com"


  b64decode = (encodedStr) ->
    new Buffer(encodedStr, 'base64').toString()

  robot.respond /(.*)のバージョン.*/i, (msg) ->
    repo = msg.match[1]

    repos_url = "#{url_api_base}/orgs/#{org_name}/repos"
    # リポジトリ一覧を取得
    github.get repos_url, {}, (res) ->
      repos = res.map (n) ->
        n['name']
      if repos.includes(repo)
        msg.send "#{repo}でいいよね？"

        file = "#{url_api_base}/repos/#{org_name}/#{repo}/contents/Gemfile"

        github.get file, {}, (res) ->
          content = b64decode(res.content)

          ruby_match = content.match(/ruby \'(\d*|\.)*\'/)
          if ruby_match != null
            ruby_version = ruby_match[0]

          rails_match = content.match(/gem \'rails\', \'(\d*|\.)*\'/)
          if rails_match != null
            rails_version = rails_match[0].replace(/gem \'rails\', /, 'rails ')

          if ruby_version == undefined && rails_version == undefined
            msg.send '設定されてないぽい'
          msg.send "```\n#{ruby_version}\n#{rails_version}\n```"
      else
        msg.send "#{repo}なんてないけど・・・"
