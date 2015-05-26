
# Carrall

Carrall is a Javascript library of functions that I have found useful in PhoneGap development.
It is implemented as a PhoneGap plugin, but has also been designed so that it can be used
outside of the PhoneGap environment as well - in other words, it will help you to make 
web-deployed versions of your PhoneGap applications.

# Methods

    if not module then module = {}

    module.exports = window.carrall =

## `setup(cb)`

Sets up Carrall's environment and calls the callback.

    fsTries: 0

    setup: (cb) ->
      _gotFS = (fs) -> 
        if (fs.isDirectory)
          carrall._fsroot = fs
          cb()
        else if carrall.fsTries < 5
          console.log("Didn't get fs object, trying again")
          carrall.fsTries++
          window.setTimeout (->carrall.setup(cb)), 500
        else
          alert("Failed to get file system object");

      if (window.cordova)
        where = if carrall.isIOS() then cordova.file.dataDirectory else cordova.file.externalApplicationStorageDirectory
        window.resolveLocalFileSystemURL(where, _gotFS, _gotFS)
      else
        cb()

## `carrall.isIOS()`

Returns true if the platform is iOS, false otherwise.

    isIOS: ->
      if (window.device && window.device.platform)
        return device.platform == "iOS"
      else return /iphone|ipad|ipod/i.test(navigator.userAgent)

## `carrall.isAndroid()`

Returns true if the platform is Android, false otherwise.

    isAndroid: ->
      if (window.device && window.device.platform)
        return device.platform == "Android"
      else return /android/i.test(navigator.userAgent)

## `carrall.hasInternetConnection()`

Returns true if the browser has an Internet connection.

    hasInternetConnection: ->
      if (navigator.connection)
        return navigator.connection.type != Connection.NONE
      else return navigator.onLine

## `carrall.hasDecentInternetConnection()`

Returns true if the browser has an Internet connection, or, in Phonegap, has a
connection of 3G or better.

    hasDecentInternetConnection: ->
      if (navigator.connection)
        return navigator.connection.type == Connection.CELL_3G || 
          navigator.connection.type == Connection.CELL_4G ||
          navigator.connection.type == Connection.WIFI || 
          navigator.connection.type == Connection.ETHERNET
      else return navigator.onLine

## `carrall.getSystemLanguage()`

Returns a two-character ISO language code for the device's interface.

    getSystemLanguage: ->
      if navigator and navigator.userAgent and (lang = navigator.userAgent.match(/android.*\W(\w\w)-(\w\w)\W/i))
        lang = lang[1];

      if (!lang && navigator) 
        if (navigator.language)
          lang = navigator.language;
        else if (navigator.browserLanguage)
          lang = navigator.browserLanguage;
        else if (navigator.systemLanguage)
          lang = navigator.systemLanguage;
        else if (navigator.userLanguage)
          lang = navigator.userLanguage;
        lang = lang.substr(0, 2);

      if !lang
        return "en"
      return lang

## `localize(sid)`

Assuming a variable of the form 
`Localisation.Strings = { en: { "full": "No space left on device", ... }, ... }`, 
this looks up the given string ID in the current interface language. Some of the
functions below will expect certain strings to be supplied.

    localize: (sid) ->
      return Localisation.Strings[carrall.getSystemLanguage()][sid] || Localisation.Strings["en"][sid]

## `orientation()`

Returns `"landscape"` or `"portrait"` as appropriate. Does not use the untrustworthy
`window.orientation`

    orientation: ->
      return if (window.innerWidth > window.innerHeight) then "landscape" else "portrait"

## `getPhonegapPath()`

Returns the file path of the application.

    getPhonegapPath: ->
      path = window.location.pathname
      phoneGapPath = path.substring(0, path.lastIndexOf('/') + 1);
      return phoneGapPath

## `rerootPathUnderApp(path)`

On upgrading an application on iOS, a new GUID is generated for the application's sandbox
directory, meaning that all old stored absolute paths are invalid. This sucks. Ideally you
should store everything as a relative path, but if you didn't this helps get back on your feet.

    rerootPathUnderApp: (path) ->
      return path if not carrall.isIOS()
      newUIDm = cordova.file.applicationStorageDirectory.match(/.*\/([0-9A-F-]{8,})/)
      if newUIDm
        newUID = newUIDm[1]
        return path.replace(/(.*\/)[0-9A-F-]{8,}/,"$1"+newUID)
      return path

## `ensureFreeSpace(howmuch, cb)`

Calls the function if enough free disk space is available; pops up a notification if not.

    ensureFreeSpace: (bytes, cb) ->
      window.requestFileSystem LocalFileSystem.PERSISTENT, bytes, cb, ->
        navigator.notification.alert(
          carrall.localize("noFreeSpace"), cb, carrall.localize("noFreeSpaceTitle"), carrall.localize("buttonOK")
        );

## `disableDoubleTap(selector)`

Disables double-tap-to-zoom on a selected element or elements.

    disableDoubleTap: (selector) ->
      $(selector).bind "touchstart", preventZoom = (e) ->
        t2 = e.timeStamp
        t1 = $(this).data("lastTouch") or t2
        dt = t2 - t1
        fingers = e.originalEvent.touches.length
        $(this).data "lastTouch", t2
        return  if not dt or dt > 500 or fingers > 1 # not double-tap
        e.preventDefault() # double tap - prevent the zoom
        # also synthesize click events we just swallowed up
        $(this).trigger("click").trigger "click"

## `stopVScroll(selector, height, strictness)`

Disables PhoneGap's annoying tendency to allow the user to scroll the viewport. (Is this
still necessary under PhoneGap 3?)

    stopVScroll: (selector, height, strictness) ->
      return if not window.cordova

      document.addEventListener "touchmove", ((e) ->
        #var me = $(document.elementFromPoint(e.pageX, e.pageY));
        me = $(e.target)
        if not me.hasClass("scrollable") and me.parents(".scrollable-container").length isnt 1
          
          #console.log("Not scrollable");
          #console.log(me);
          e.preventDefault()
        else
      ), false
      touch_event_start = undefined
      $(selector).bind "touchstart", (event) ->
        touch_event_start = event

      $(selector).bind "touchmove", (event) ->
        y_diff = parseInt((event.originalEvent.pageY - touch_event_start.originalEvent.pageY))
        if y_diff > height or (strictness and Math.abs(y_diff) > 5)
          
          #console.log(y_diff);
          event.preventDefault()
          false

## `saveJSONFile(filename, object)`

Writes out the object as a JSON file to the permanent filesystem.

    saveJSONFile: (filename, object, replacer) ->
      if (!window.cordova)
        window.localStorage.setItem(filename, JSON.stringify(object, replacer))
        return

      fail = (e) -> console.log e
      _write = (writer) -> writer.write JSON.stringify(object, replacer)
      _gotFileEntry = (e) -> e.createWriter _write, fail

      carrall._fsroot.getFile filename,
        create: true
        exclusive: false
      , _gotFileEntry, fail


## `loadJSONFile(filename, root, key, cb)`

Deserializes the JSON contained in a file into a variable specified by `root[key]` and
then calls the given callback.

    loadJSONFile: (filename, root, key, cb) ->

      fail = cb
      if (!window.cordova)
        data = window.localStorage.getItem(filename)
        root[key] = JSON.parse(data) if data
        return cb()

      _gotFile = (file) ->
        reader = new FileReader()
        reader.onloadend = (evt) ->
          try
            res = JSON.parse(evt.target.result)
          catch
            # Do nothing
          root[key] = res  if res
          cb()

        reader.onerror = (e) -> console.log e

        reader.readAsText file
        # cb()  if file.size is 0

      _gotFileEntry = (e) -> e.file _gotFile, fail
        
      carrall._fsroot.getFile filename,
        create: true
        exclusive: false
      , _gotFileEntry, fail

## `saveXML(filename, dom, cb)`

Writes out the object as an XML file to the permanent filesystem and calls the callback.

    saveXML: (path, dom, cb) ->
      xml = (new XMLSerializer()).serializeToString(dom[0])
      if (!window.cordova)
        window.localStorage.setItem(path, xml)
        return cb()

      fail = (e) -> console.log e
      _write = (writer) ->
        writer.onwriteend = cb
        writer.write xml

      _gotFileEntry = (e) -> e.createWriter _write, fail
      # Make relative path
      path = path.replace(carrall._fsroot.fullPath+"/", "")
      console.log("Trying to save "+path)
      carrall._fsroot.getFile path,
        create: true
        exclusive: false
      , _gotFileEntry, fail

## `loadXML(filename, cb, errorcb)`

Loads the XML serialised in the filename into a DOM object, calling the callback on the result
or calling error callback on error.

    loadXML: (path, cb, ecb) ->
      if (!window.cordova)
        data = window.localStorage.getItem(path)
        return cb($data) if data
        return ecb()

      if !path.match(/^file:\//) # Android does, iOS doesn't
        path = "file://"+path
      if (!ecb)
        ecb = (e) -> console.log(e)
      noncedPath = path+"?"+(new Date()).getTime()
      $.ajax(
          url: noncedPath
          method: "GET"
          dataType: "xml"
          error: ecb
        ).done (data) -> 
          cb($(data))
