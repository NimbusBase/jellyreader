app = angular.module('app', []);

app.directive('fitlerlink',()->
  restrict: 'A',
  scope: true
  link: (scope, element, attributes)->
    element.bind('click',()->
      $('.filter_link').each((i,k)->
        $(k).removeClass('selected')
      )
      element.addClass('selected')
    )
)

FeedCtrl = ($scope) ->
  $scope.feeds = []
  $scope.sites = []
  $scope.selectedIndex = 0
  $scope.unread = 0
  $scope.today = 0
  $scope.starred = 0
  $scope.current_item = null
  $scope.selected_site = null
  $scope.app_loading = true
  $scope.list = []
  $scope.page = 1
  $scope.channel = 'all'
  #configs 
  per_page = 20
  paginator = {}

  $scope.safeApply = (fn) ->
    phase = @$root.$$phase
    if phase is "$apply" or phase is "$digest"
      fn()  if fn and (typeof (fn) is "function")
    else
      @$apply fn

  $scope.change_current = (item,ind)->
    
    if item.content?
      item.display = decodeURIComponent(window.atob(item.content))
    else
      item.display = decodeURIComponent(window.atob(item.description))
    item.display_date = moment(item.updated).format("MMMM Do YYYY, h:mm:ss a")
    $scope.selectedIndex = ind
    
    #update on model
    feedItem = FeedItem.findByAttribute('link', item.link)
    #console.log("feedItem", feedItem)
    if feedItem? and  feedItem.read is false
      item.read = true
      feedItem.read = true
      feedItem.save()
      # item.save()
      $scope.unread = if $scope.unread then $scope.unread-1 else 0
    
    $scope.current_item = item

  $scope.load = ->
    console.log("loading")
    $scope.feeds = []
    $scope.sites = []
    i = 0
    u = 0
    t = 0
    s = 0
    
    #feed sites
    for site in FeedSite.all()
      $scope.sites.push(site)
    
    #feeds
    for feed in FeedItem.all()
      #@todo send this to web worker ??
      #flush expired unread items

      time = moment().format('YYYY-MM-DD')
      if feed.read and moment(feed.updated).isBefore(time) and !feed.star
        feed.destroy()
      else
        feed.from_now = moment(feed.updated).fromNow() if feed.updated
        feed.ind = i
        i = i + 1
        $scope.feeds.push(feed)
        #$scope.feed[$scope.feed.length-1].display_date = moment(feed.updated).format("MMMM Do YYYY, h:mm:ss a")
        u = u + 1 if feed.read is false
        t = t + 1 if moment().isSame(feed.updated, 'day')
        s = s + 1 if feed.star is true

    $scope.unread = u
    $scope.today = t
    $scope.starred = s

    #sort feeds
    $scope.feeds.sort( (a,b)->
      if moment(a.updated).isAfter(b.updated) then -1 else 1
    )
    
    $scope.app_loading = false
    $scope.list = $scope.feeds.slice(0,per_page*$scope.page)
    if $scope.current_item is null and $scope.list.length isnt 0
      $scope.current_item = $scope.change_current($scope.list[0])
    #set up painator
    paginator.all = 
      page :1
      total:$scope.feeds.length
    $scope.safeApply()
  $scope.load()

  $scope.load_more = ()->
    pager = get_page($scope.channel)
    if per_page*(pager.page)>$scope.feeds.length
      $('#app_hint').text('No More').fadeIn(1500).fadeOut()
      return false 
    set_page($scope.channel,pager.page+1)
    $scope.list = $scope.feeds.slice(0,per_page*(pager.page+1))
  $scope.star = (item) ->
    #update on model
    item.star = true
    item.save()    
    
    $scope.starred = $scope.starred + 1
  $scope.unstar =(item) ->
    item.star = false
    item.save()
    $scope.starred -=1;

  set_page = (key,page,total)->
    console.log key+'+'+page
    total = get_page(key).total if !total
    paginator[key] = 
      'page' : page
      'total': total
  get_page = (key)->
    if !paginator[key]
      paginator[key] = 
        'page' : 1
        'total': $scope.feeds.length
    paginator[key]
  #filter by status
  $scope.filter_status = (status,obj,index) ->
    channel = status
    filter = []
    for feed in FeedItem.all()
      switch status
        when 'unread'
          if !feed.read then filter.push(feed)
        when 'today'
          if moment().isSame(feed.updated,'day') then filter.push(feed)
        when 'star'
          if feed.star then filter.push(feed)
        when 'site'
          if feed.site is obj.title then filter.push(feed)
          channel = 'site_'+index

      feed.from_now = moment(feed.updated).fromNow() if feed.updated
    $scope.channel = channel
    $scope.selected_site = obj
    #sort feeds
    filter.sort( (a,b)->
      if moment(a.updated).isAfter(b.updated) then -1 else 1
    )
    if paginator[channel]
      $scope.list = filter.slice(0,per_page*paginator[channel].page)
    else
      $scope.list = filter.slice(0,per_page)
      set_page(channel,1,filter.length)

    $scope.feeds = filter 
    if $scope.current_item is null and $scope.feeds.length isnt 0
      $scope.current_item = $scope.change_current($scope.feeds[0])
    angular.element(this).addClass('selected')

  $scope.add_feed_site = () ->
    
    address = $("#rss_address").val()
    console.log(address)
    
    load_rss_feed(address)
    $scope.app_loading = false
    #clear input
    $('#rss_address').val('')
    window.location.href = window.location.href + '#!'

  $scope.del_feed = (feed) ->
    feedItem = FeedItem.findByAttribute('link',feed.link)
    index = $scope.feeds.indexOf(feed)
    list_index = $scope.list.indexOf(feed)
    $scope.feeds.splice(index,1)
    $scope.list.splice(list_index,1)
    $scope.starred-- if feed.star and $scope.starred>0
    $scope.today-- if moment().isSame(feed.updated, 'day') and $scope.today>0
    feedItem.destroy()

    show = if index < $scope.feeds.length and $scope.feeds.length>0 then index else index-1
    
    $scope.current_item = $scope.feeds[show]
    if $scope.feeds.length isnt 0
      $scope.change_current($scope.current_item)
    $scope.selectedIndex = show;
  $scope.refresh = ()->
    if !FeedSite.all().length
      return
    
    $scope.app_loading = true
    refresh()
  $scope.remove_selected_site = () ->
    site = FeedSite.findByAttribute('link',$scope.selected_site.link)
    site.destroy()
    # todo delete site feeds ?
    for feed in FeedItem.all()
      if feed.site== site.title and !feed.star
        feed.destroy()
    index = $scope.sites.indexOf($scope.selected_site)
    $scope.sites.splice(index,1)
    $scope.load();

  if $scope.current_item is null and $scope.feeds.length isnt 0
      $scope.current_item = $scope.change_current($scope.feeds[0])
  else if $scope.feeds.length is 0
    obj = 
      'link': "http://nimbusbase.com"
      'title': "Add some feeds!"
      'display': "Welcome to JellyReader. To add some feeds to your RSS. Click Add Feed and put in a website or blog URL. <br /> <img src='landingpage_logo.png' />"
      'author': "Ray Wang"
      'display_date': moment().format("MMMM Do YYYY, h:mm:ss a")
      'feed': "http://nimbusbase.com" # host url
      'read': false
      'star': false
      'site': "JellyReader"
    $scope.current_item = obj
