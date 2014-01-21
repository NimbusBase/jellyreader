# setup sync
sync_object = 
  "GDrive":
    "key": "762177952485-isd11r5irt52dgdn2hriu2rd90e84vr2.apps.googleusercontent.com"
    "scope": "https://www.googleapis.com/auth/drive"
    "app_name": "jellyreader"
  "Dropbox":
    "key": "q5yx30gr8mcvq4f"
    "secret": "qy64qphr70lwui5"
    "app_name": "jellyreader"
Nimbus.Auth.setup(sync_object)
###
  reader models
### 
FeedItem = Nimbus.Model.setup 'FeedItem', ['link', 'title', 'description', 'author', 'updated', 'feed', 'read', 'star', 'image', "content", "site"]
FeedSite = Nimbus.Model.setup 'FeedSite', ['title', 'link', 'type', 'description', 'updated', "icon"]

Nimbus.Auth.set_app_ready () ->
  console.log("app ready called")
  if Nimbus.Auth.authorized()
    $('.app_spinner').show();
    FeedItem.sync_all(()->
      FeedSite.sync_all(() ->
        $("#loading").addClass("loaded")
        $('.app_spinner').hide();
        angular.element(document.getElementById('app_body')).scope().load()
      )
    )
    return
###
  main reader class
###

window.CORS_PROXY = "http://192.241.167.76:9292/"

load_rss_feed = (url)->
  # regular test first
  protocl = 'http://'
  if url.indexOf('https://') is 0
    protocl = 'https://'
  url = protocl + url.replace('http://','').replace('https://','')

  Reader.cache = 
    'url' : url
    'icon' : ''

  if rss=Reader.get_rss(url)
    feedSite = FeedSite.findByAttribute('link', Reader.cache.url)
    if !feedSite
      console.log 'create site'
      # find rss url first
      obj = 
        name: ""
        link: rss
        type: ""
        description: ""
        updated: ""
        icon: Reader.cache.icon
      feedSite = FeedSite.create(obj)
    if !feedSite.icon
      Reader.get_icon(feedSite.link,(icon_url)->
        feedSite.icon = icon_url
        feedSite.save()
      ) 
    Reader.get_feeds(feedSite.link,(data)->
      if data
        process_data(data,feedSite)
        angular.element(document.getElementById('app_body')).scope().load()
    ) 
  else
    console.log 'not valid'
    iosOverlay(
      icon : 'img/cross.png'
      text : 'Invalid Url'
      duration : 1500
    )
    $('span.spinner').hide()

window.process_data = (data,site)->
  #update feed site
  site.title = data.title
  site.description = data.description
  site.type = data.type
  site.updated = data.updated
  site.save() 
  return unless data.items 
  for item in data.items
    feedItem = FeedItem.findByAttribute('title', item.title)
    image = Reader.get_first_image(item.content)
    if not feedItem
      obj =
        'link': item.link
        'title': item.title
        'description': btoa(encodeURIComponent(item.description))
        'author': item.author
        'updated': item.updated
        'feed': data.link # host url
        'read': false
        'star': false
        'content': btoa(encodeURIComponent(item.content)) if item.content? and item.content isnt ""
        'site': data.title
      feedItem = FeedItem.create(obj)
      console.log 'create new: '+item.title
    else
      feedItem.title = item.title
      feedItem.description = btoa(encodeURIComponent(item.description))
      feedItem.author = item.author
      feedItem.updated = item.updated
      feedItem.feed = data.link
      feedItem.content = btoa(encodeURIComponent(item.content)) if item.content? and item.content isnt ""
      feedItem.site = data.title
      console.log 'updatea : '+item.title

    if !feedItem.image
      feedItem.image = image
    feedItem.save()
  
window.refresh = ->
  window.total_refresh_task = FeedSite.all().length
  window.current_refresh_task = 0
  start_next_task()

window.start_next_task = ()->
  return if window.current_refresh_task is total_refresh_task
  site = FeedSite.all()[window.current_refresh_task]
  Reader.get_feeds(site.link,(data)->
    process_data(data,site)
    window.current_refresh_task++
    if window.current_refresh_task<window.total_refresh_task
      start_next_task()
    else
      window.current_refresh_task = 0
      # stop animation
      angular.element(document.getElementById('app_body')).scope().load()
  )
  
$ ->
  if localStorage['state']
    $('.spinner').show()    

  $("#login_dropbox").click( ()->
    console.log("Auth button clicked")
    Nimbus.Auth.authorize('Dropbox')
  )

  $("#login_gdrive").click( ()->
    console.log("Auth button clicked")
    Nimbus.Auth.authorize('GDrive')
  )  

  $("#logout").click( ()->
    Nimbus.Auth.logout()
  )

  $("#refresh").click( ()->
    refresh()
  )

  if document.URL[0..5] is "chrome"
    log("Chrome edition authentication")
    chrome.tabs.onUpdated.addListener( (tabId, changeInfo, tab) -> 
      if tab.title is "API Request Authorized - Dropbox"
        chrome.tabs.remove(tabId)
        Nimbus.Client.Dropbox.get_access_token( (data) -> 
          localStorage["state"] = "Working" 
          Nimbus.Auth.authorized_callback() if Nimbus.Auth.authorized_callback?
          
          Nimbus.Auth.app_ready_func()
          console.log("NimbusBase is working! Chrome edition.")
          Nimbus.track.registered_user()
        )
    )

  EffecktDemos = init: ->
    $(window).load ->
      $(".no-transitions").removeClass "no-transitions"
  
  EffecktDemos.init()
 