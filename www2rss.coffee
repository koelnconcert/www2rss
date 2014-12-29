fs = require 'fs'
rss = require 'rss'
request = require 'request'
iconv = require 'iconv'
cson = require 'cson'
extend = require 'extend'

feeds = cson.parseFileSync 'feeds.cson'
config = cson.parseFileSync 'config.cson'

generate_feed = (config, html) ->
  if config.regexp.content?
    re = new RegExp config.regexp.content
    content = html.match(re)[0]
  else
    content = html

  re = new RegExp config.regexp.split

  lines = content.split re

  template = (template, arr) ->
    template.replace /\$([0-9]+)/g, (m, num) -> arr[num]

  feed = new rss config.feed
  # console.log (line[0..20] for line in lines)
  for line in lines
    re = new RegExp config.regexp.item
    entries = line.match re
    # console.error entries[1..] if entries?
    if entries?
      item =
        site_url: config.source.url
      for key, value of config.item
        if Array.isArray value
          item[key] = ( template val, entries for val in value )
        else
          item[key] = template value, entries
      feed.item item

  feed.xml indent:true


for id, feed of feeds
  # continue unless id.match /ptb/
  console.log "generate feed '#{id}'"
  do (id, feed) ->
    charset = feed.source.charset

    opts = extend {}, config.request,
      url : feed.source.url
    opts.encoding = null if charset?

    request opts, (error, response, body) ->
      if error || response.statusCode != 200
        console.error "error getting #{feed.url}"
      else
        if charset?
          ic = new iconv.Iconv charset, 'utf-8'
          body = ic.convert(body).toString('utf-8')
        try
          xml = generate_feed feed, body
          fs.writeFile "feeds/#{id}.xml", xml
        catch err
          console.log "error with #{id}"
