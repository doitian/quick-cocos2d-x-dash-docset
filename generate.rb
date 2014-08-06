#!/usr/bin/env ruby
# coding: utf-8
require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'sqlite3'
require 'uri'

FileUtils.rm_rf 'quick-cocos2d-x.docset'
FileUtils.mkdir_p 'quick-cocos2d-x.docset/Contents/Resources/Documents'

CONTENT = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>quick-cocos2d-x</string>
	<key>CFBundleName</key>
	<string>quick-cocos2d-x</string>
	<key>DocSetPlatformFamily</key>
	<string>quick</string>
	<key>isDashDocset</key>
	<true/>
	<key>dashIndexFilePath</key>
	<string>index.html</string>
	<key>DashDocSetFamily</key>
	<string>dashtoc</string>
</dict>
</plist>
XML

File.open('quick-cocos2d-x.docset/Contents/Info.plist', 'w') do |f|
  f.write CONTENT
end

FileUtils.cp 'icon.png', 'quick-cocos2d-x.docset/icon.png'

db = SQLite3::Database.new 'quick-cocos2d-x.docset/Contents/Resources/docSet.dsidx'
db.execute <<-SQL
  CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);
SQL
db.execute <<-SQL
  CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);
SQL

INSERT = <<-SQL
INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, ?, ?)
SQL


db.execute INSERT, ['init', 'Module', 'index.html']

index = Nokogiri::HTML(File.read('quick-cocos2d-x/docs/api/index.html'))
ul = index.at('//td[@id="navigation"]/h2[text()="Modules"]').next_element
ul.css('a[href]').each do |a|
  db.execute INSERT, [a.text.strip, 'Module', a[:href]]
end

FileUtils.cp Dir['quick-cocos2d-x/docs/api/*.{js,css}'], 'quick-cocos2d-x.docset/Contents/Resources/Documents/'

Dir['quick-cocos2d-x/docs/api/*.html'].each do |f|
  basename = File.basename(f)
  html = Nokogiri::HTML(File.read(f))

  if (title = html.at('title'))
    title.inner_html = title.text.sub(/^quick-cocos2d-x API Documents - /, 'Module ')
  end

  anchor_map = {}
  html.css('.function_list td.name a[href]').each do |a|
    anchor_map[a[:href]] = a.text.strip
    db.execute INSERT, [a.text.strip, 'Function', basename + a[:href]]
  end

  html.css('dl.function > a[name]').each do |a|
    if (entry = anchor_map['#' + a[:name]])
      a.before <<-HTML
        <a name="//apple_ref/cpp/Function/#{URI.encode(entry)}" class="dashAnchor"></a>
      HTML
    end
  end

  File.open("quick-cocos2d-x.docset/Contents/Resources/Documents/#{basename}", 'w') do |out|
    out.write html.to_html(encoding: 'UTF-8')
  end
end

FileUtils.cp_r 'quick-cocos2d-x/docs/howto', 'quick-cocos2d-x.docset/Contents/Resources/Documents/howto'
db.execute INSERT, ['API', 'Guide', 'index.html']
db.execute INSERT, ['设置 Mac 下的编译环境', 'Guide', 'howto/setup_development_environment_on_mac/zh.html']
db.execute INSERT, ['设置 Windows 下的编译环境', 'Guide', 'howto/setup_development_environment_on_windows/zh.html']
db.execute INSERT, ['如何使用 proj.mac 和 proj.win32 工程', 'Guide', 'howto/use-project-mac-and-win/zh.html']
