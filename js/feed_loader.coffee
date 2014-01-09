# importScripts('jquery.hive.pollen.js')
# jQuery = $
# indexOf = String.prototype.indexOf
# replace = String.prototype.replace
# length = Array.prototype.length
# exec = RegExp.prototype.exec
# importScripts('tinyxmldom.js')
importScripts('base64.js')

strip_image = (html)->
	regexp = /<img\s*[^>]*\s*src='?([^\s^>]+)'?[^>]*>/
	regexp.test(html)

	first = RegExp.$1
	if first[first.length-1] is '/'
		first = first.substr(0,first.length-2)
	
	first.replace('"', "").replace('"', "").replace("'", "").replace("'", "")
onmessage = (evt)->
	json = JSON.parse(evt.data)
	#save feed update time and other info
	result = 
		site : {}
		items : []
	# filter site data
	if json.channel
		result.site.description = json.channel.description.Text
	else if json.description
		result.site.description = json.description.Text

	if json.channel
		result.site.title = json.channel.title.Text
	else if json.title
		result.site.title = json.title.Text

	# update
	if json.channel and json.channel.lastBuildDate
		result.site.updated = json.channel.lastBuildDate.Text
	else if json.updated
		result.site.updated = json.updated.Text
	# image
	if json.channel and json.channel.image
		result.site.icon = json.channel.image.url.Text
	
	if json.channel
		for item in json.channel.item
			if item['content:encoded']	
				content = item['content:encoded'].Text
			else if item['content']
				# use content
				content = item['content'].Text
			else
				# use description
				content = item['description'].Text
		
			obj = 
				'link': item.link.Text
				'title': item.title.Text
				'description': base64.encode(encodeURIComponent(item.description.Text))
				'author': if item.author then item.author.Text else ''
				'updated': if item.pubDate then item.pubDate.Text else result.site.updated
				'feed': item.link.Text # host url
				'read': false
				'star': false
				'content': base64.encode(encodeURIComponent(content))
				'site': json.channel.title.Text
			if item['media:thumbnail']
				obj.image = item['media:thumbnail']['@url']
			else if item['image'] or item['thumbnail']
				obj.image = item['image'] or item['thumbnail']
			else
				obj.image = strip_image(content)
			# set author
			if !item.author and item['dc:creator']
				obj.author = item['dc:creator'].Text
			else
				obj.author = 'U'
			
			result.items.push(obj)
	else if json.entry
		for entry in json.entry
			content = entry['content'].Text
			obj = 
				'link': entry.link['@href']
				'title': entry.title.Text
				'updated': entry.updated.Text
				'feed': entry.link.Text # host url
				'read': false
				'star': false
				'content' : base64.encode(encodeURIComponent(content))
				'site': json.title.Text
				'author': if entry.author then entry.author.Text else ''
			# image 
			obj.image = strip_image(content)
			result.items.push(obj)

	postMessage(JSON.stringify(result))

	return
