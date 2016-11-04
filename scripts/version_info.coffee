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

        ruby_url = "#{url_api_base}/repos/#{org_name}/#{repo}/contents/Gemfile"

        github.get ruby_url, {}, (res) ->
          content = b64decode(res.content)
          ruby_version = content.match(/ruby \'(\d*|\.)*\'/)[0]
          rails_version = content.match(/gem \'rails\', \'(\d*|\.)*\'/)[0].replace(/gem \'rails\', /, 'rails ')

          msg.send "```\n#{ruby_version}\n#{rails_version}\n```"
      else
        msg.send "#{repo}なんてないけど・・・"
