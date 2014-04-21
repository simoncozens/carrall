
# Carrall

Carrall is a Javascript library of functions that I have found useful in PhoneGap development.
It is implemented as a PhoneGap plugin, but has also been designed so that it can be used
outside of the PhoneGap environment as well - in other words, it will help you to make 
web-deployed versions of your PhoneGap applications.

# Methods

    module.exports = window.carrall =

## `setup(cb)`

Sets up Carrall's environment and calls the callback.

    setup: (cb) ->
      _gotFS = (fs) -> 
        carrall._fsroot = fs.root
        cb()

      if (window.requestFileSystem) # We resume that we're running under Phonegap, but...
        window.requestFileSystem LocalFileSystem.PERSISTENT, 0, _gotFS, cb
      else
        cb()

## `carrall.isIOS()`

Returns true if the platform is iOS, false otherwise.

    isIOS: ->
      if (window.device && window.device.platform)
        return device.platform == "iOS"
      else return /iphone|ipad|ipod/i.test(navigator.userAgent)

## `carrall.hasInternetConnection()`

Returns true if the browser has an Internet connection.

    hasInternetConnection: ->
      return navigator.onLine || (navigator.connection.type != Connection.NONE)

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

      return lang

## `localize(sid)`

Assuming a variable of the form 
`Localisation.Strings = { en: { "full": "No space left on device", ... }, ... }`, 
this looks up the given string ID in the current interface language. Some of the
functions below will expect certain strings to be supplied.

    localize: (sid) ->
      return Localisation.Strings[carrall.getSystemLanguage()][sid] || "Lazy developer did not provide string for "+sid+" in language "+carrall.language;

## `orientation()`

Returns `"landscape"` or `"portrait"` as appropriate.

    orientation: ->
      if (window.orientation == -90 || window.orientation == 90)
        return "landscape";
      return "portrait";

## `getPhonegapPath()`

Returns the file path of the application.

    getPhonegapPath: ->
      path = window.location.pathname
      phoneGapPath = path.substring(0, path.lastIndexOf('/') + 1);
      return phoneGapPath

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

    saveJSONFile: (filename, object) ->
      fail = (e) -> console.log e
      _write = (writer) -> writer.write JSON.stringify(object)
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
      _gotFile = (file) ->
        reader = new FileReader()
        reader.onloadend = (evt) ->
          res = JSON.parse(evt.target.result)
          root[key] = res  if res
          cb()

        reader.onerror = (e) -> console.log e

        reader.readAsText file
        cb()  if file.size is 0

      _gotFileEntry = (e) -> e.file _gotFile, fail
        
      carrall._fsroot.getFile filename,
        create: true
        exclusive: false
      , _gotFileEntry, fail

## `saveXML(filename, dom, cb)`

Writes out the object as an XML file to the permanent filesystem and calls the callback.

    saveXML: (path, dom, cb) ->
      xml = (new XMLSerializer()).serializeToString(dom[0])
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