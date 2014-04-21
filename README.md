
# Carrall

Carrall is a Javascript library of functions that I have found useful in PhoneGap development.
It is implemented as a PhoneGap plugin, but has also been designed so that it can be used
outside of the PhoneGap environment as well - in other words, it will help you to make 
web-deployed versions of your PhoneGap applications.

# Methods

## `setup(cb)`

Sets up Carrall's environment and calls the callback.

## `carrall.isIOS()`

Returns true if the platform is iOS, false otherwise.

## `carrall.hasInternetConnection()`

Returns true if the browser has an Internet connection.

## `carrall.getSystemLanguage()`

Returns a two-character ISO language code for the device's interface.

## `localize(sid)`

Assuming a variable of the form 
`Localisation.Strings = { en: { "full": "No space left on device", ... }, ... }`, 
this looks up the given string ID in the current interface language. Some of the
functions below will expect certain strings to be supplied.

## `orientation()`

Returns `"landscape"` or `"portrait"` as appropriate.

## `getPhonegapPath()`

Returns the file path of the application.

## `ensureFreeSpace(howmuch, cb)`

Calls the function if enough free disk space is available; pops up a notification if not.

## `disableDoubleTap(selector)`

Disables double-tap-to-zoom on a selected element or elements.

## `stopVScroll(selector, height, strictness)`

Disables PhoneGap's annoying tendency to allow the user to scroll the viewport. (Is this
still necessary under PhoneGap 3?)

## `saveJSONFile(filename, object)`

Writes out the object as a JSON file to the permanent filesystem.

## `loadJSONFile(filename, root, key, cb)`

Deserializes the JSON contained in a file into a variable specified by `root[key]` and
then calls the given callback.

## `saveXML(filename, dom, cb)`

Writes out the object as an XML file to the permanent filesystem and calls the callback.

## `loadXML(filename, cb, errorcb)`

Loads the XML serialised in the filename into a DOM object, calling the callback on the result
or calling error callback on error.

