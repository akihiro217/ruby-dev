#!/usr/local/bin/ruby

require './database.rb'
require 'mysql'
require 'cgi'

Site_Name = "Ruby-dev App Ranking"

client = Mysql.connect($db_host, $db_user, $db_password, $db_name)

 # GET/POST
cgi = CGI.new

limit = 20
offset  = 0
page = 1
if cgi["page"] != "" then
    page = cgi["page"].to_i
    offset = (limit * page) - limit
end

# パラメータが不正なときリダイレクト
if page < 0 then
    page = 1
    redirect_url = "top.rb#redirect"
    print cgi.header({ 'status' => 'REDIRECT', 'Location' => redirect_url })
    exit
end

##################################################
# ここから出力
##################################################
print "content-type: text/html\n\n"

print <<__HTML__
<html>
    <head>
        <title>#{Site_Name}</title>
        <meta http-equiv="content-type" content="text/html; charset=utf8">
        <meta name="viewport" content="width=320">
        <style type="text/css">
        .title {
            color: green;
        }
        .icon {
            height: 90px;
            float: left;
            margin: 0px 10px 10px 0;
        }
        .description {
        }
        .app {
            padding: 10px;
            margin: 10px;
            background-color: white;
            overflow: hidden;
            -webkit-border-radius: 8px;
        }
        .app.first {
            background-color: gold;
        }
        .app.second {
            background-color: silver;
        }
        .app.third {
            background-color: #CD7F32;
        }
        .rank {
            font-size: 24px;
            font-weight: bold;
        }
        .pager {
            text-align: center;
            background-color: lightyellow;
            padding: 5px;
            margin: 5px;
        }
        .pager a:link, .pager a:visited {
            font-size: 24px;
            font-weight: bold;
            color: green;
            padding: 5px;
        }
        input[name=search_word] {
            font-size: 24px;
        }
        input[name=submit] {
            font-size: 24px;
        }
        </style>
    </head>
<body>

<div>
    <h1 class="title">#{Site_Name}</h1>
    <form action="search.rb" method="post">
        <input type="text" name="search_word">
        <input type="submit" name="submit" value="検索">
    </form>
</div>
__HTML__

description_max_length = 100

##################################################
# LIMIT, OFFSET によるページあたりのアプリ情報を取得
##################################################
sql = "SELECT a.id, a.package_name, b.app_name, b.description, b.click_count FROM aso_db.android_masters a left join google_play b on a.package_name = b.package_name WHERE a.deactivate_date is null and b.app_name not regexp '[a-z]' ORDER BY click_count DESC, a.id LIMIT #{limit} OFFSET #{offset}"

rank = 1 + offset # ランキング
client.query(sql).each{
|id, package_name, app_name, description, click_count|
  id_ = sprintf('%02d', id)
  description_ = description.gsub(/<br>/, "")[0, description_max_length] #メソッドチェーン記述
  if description_max_length < description.length then
    description_ += "..."
  end
  
  app_rank = ""
  case rank
    when 1 then
        app_rank = "first"
    when 2 then
        app_rank = "second"
    when 3 then
        app_rank = "third"
    end
  
  print "<div class=\"app #{app_rank}\">"
      print "<a href=\"detail.rb?id=#{package_name}\">"
        print "<img class=\"icon\" src=\"/img/google_play/icon/#{package_name}.png\">"
      print "</a>"
      
      print "<span class=\"rank\">#{rank}位<br><a href=\"detail.rb?id=#{package_name}\">#{app_name}</a></span><br>"
      print "(#{package_name})<br>"
      #print "クリック数：#{click_count}<br>"
      print "<span class=\"description\">#{description_}</span> "
      print "<a href=\"detail.rb?id=#{package_name}\">もっとみる</a>"
  print "</div>"
  print "<div style=\"clear: both;\"></div>\n"
  
  rank += 1
}

##################################################
# ページャーの出力（固定）
##################################################
print "<div class=\"pager\">"
for num in 1..10 do
    n = num
    print "<a class=\"link\" href=\"?page=#{n}\">#{n}</a>\n"
end
print "</div>"

print <<__HTML__
</body>
</html>
__HTML__
