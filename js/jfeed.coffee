Object.extend = (destination, source) ->
	for property in source
    	destination[property] = source[property]; 
	destination
#sync op
sync = (config,is_async)->
	if is_async then is_async=true else is_async=false

	if location.href.indexOf('chrome') is -1
		config.url = config.url.replace('http://', "").replace('www', "")
		config.url = 'http://192.241.167.76:9292/'+config.url

	req = new XMLHttpRequest()
	method = if config.method then config.method else 'get'
	req.open('get',config.url,is_async)
	req.onreadystatechange = ()->
		if (req.readyState == 4 and req.status) 
			config.success(req.response)
	req.send(null)

#async op
async = (config)->
	sync(config,true)

getFeed = (options)->
	if options.url
		config = 
			type: 'GET',
			url: options.url,
			dataType: "xml",
			success: (xml)->
				feed = new JFeed(xml);
				options.success(feed) if (jQuery.isFn(options.success)) 
		async config 

class JFeed
	constructor: (xml) ->
		@parse xml if xml
	
JFeed.prototype = 
	type : ''
	version : ''
	title: ''
	link: ''
	description: ''
	parse: (xml)->
		if (xml.indexOf('<channel>') > 0) 
			this.type = 'rss'
			feedClass = new JRss(xml)
			
		$.extend(this,feedClass)
class JFeedItem
	constructor: () ->

JFeedItem.prototype = 
    title: '',
    link: '',
    description: '',
    updated: '',
    id: '',
    author: ''

class JRss
	constructor: (xml)->
		@_parse xml
JRss.prototype  = 
	_parse: (xml) ->
		xml_doc = new XMLDoc(xml)
		doc_node = xml_doc.docNode

		if !doc_node.getElements('rss')
			this.version = '1.0'
		else
			this.version = '2.0'

		channel = doc_node.getElements('channel')[0]

		this.title = channel.getElements('title')[0].getText()
		this.link = channel.getElements('link')[0].getText()
		this.description = channel.getElements('description')[0].getText()
		if channel.getElements('lastBuildDate')[0]
			this.updated = channel.getElements('lastBuildDate')[0].getText()  

		feed = this
		feed.items = []

		if !channel.getElements('item').length
			return feed
		
		for row in channel.getElements('item')
			item = new JFeedItem()
			item.title = row.getElements('title')[0].getText()
			item.link = row.getElements('link')[0].getText()
			item.description = row.getElements('description')[0].getText()
			item.updated = row.getElements('pubDate')[0].getText() if row.getElements('pubDate')[0]
			if row.getElements('guid')[0]
				item.id = row.getElements('guid')[0].getText()
			if row.getElements('dc:creator')[0]
				item.author = row.getElements('dc:creator')[0].getText()
			else if row.getElements('author')[0]
				item.author = row.getElements('author')[0].getText()
			if row.getElements('content:encoded')[0]
				item.content = row.getElements('content:encoded')[0].getText()
			else
				item.content = row.getElements('description')[0].getText()
			#console.log("FIND date", jQuery(this).find('date').eq(0).text());
			item.updated = row.getElements('dc:date')[0].getText() if row.getElements('dc:date')[0] 	
			feed.items.push(item)
		feed