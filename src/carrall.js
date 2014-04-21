window.carrall = {
  setup: function(cb) {
    var _gotFS;
    _gotFS = function(fs) {
      carrall._fsroot = fs.root;
      return cb();
    };
    if (window.requestFileSystem) {
      return window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, _gotFS, cb);
    } else {
      return cb();
    }
  },
  isIOS: function() {
    if (window.device && window.device.platform) {
      return device.platform === "iOS";
    } else {
      return /iphone|ipad|ipod/i.test(navigator.userAgent);
    }
  },
  hasInternetConnection: function() {
    return navigator.onLine || (navigator.connection.type !== Connection.NONE);
  },
  getSystemLanguage: function() {
    var lang;
    if (navigator && navigator.userAgent && (lang = navigator.userAgent.match(/android.*\W(\w\w)-(\w\w)\W/i))) {
      lang = lang[1];
    }
    if (!lang && navigator) {
      if (navigator.language) {
        lang = navigator.language;
      } else if (navigator.browserLanguage) {
        lang = navigator.browserLanguage;
      } else if (navigator.systemLanguage) {
        lang = navigator.systemLanguage;
      } else if (navigator.userLanguage) {
        lang = navigator.userLanguage;
      }
      lang = lang.substr(0, 2);
    }
    return lang;
  },
  localize: function(sid) {
    return Localisation.Strings[carrall.getSystemLanguage()][sid] || "Lazy developer did not provide string for " + sid + " in language " + carrall.language;
  },
  orientation: function() {
    if (window.orientation === -90 || window.orientation === 90) {
      return "landscape";
    }
    return "portrait";
  },
  getPhonegapPath: function() {
    var path, phoneGapPath;
    path = window.location.pathname;
    phoneGapPath = path.substring(0, path.lastIndexOf('/') + 1);
    return phoneGapPath;
  },
  ensureFreeSpace: function(bytes, cb) {
    return window.requestFileSystem(LocalFileSystem.PERSISTENT, bytes, cb, function() {
      return navigator.notification.alert(carrall.localize("noFreeSpace"), cb, carrall.localize("noFreeSpaceTitle"), carrall.localize("buttonOK"));
    });
  },
  disableDoubleTap: function(selector) {
    var preventZoom;
    return $(selector).bind("touchstart", preventZoom = function(e) {
      var dt, fingers, t1, t2;
      t2 = e.timeStamp;
      t1 = $(this).data("lastTouch") || t2;
      dt = t2 - t1;
      fingers = e.originalEvent.touches.length;
      $(this).data("lastTouch", t2);
      if (!dt || dt > 500 || fingers > 1) {
        return;
      }
      e.preventDefault();
      return $(this).trigger("click").trigger("click");
    });
  },
  stopVScroll: function(selector, height, strictness) {
    var touch_event_start;
    document.addEventListener("touchmove", (function(e) {
      var me;
      me = $(e.target);
      if (!me.hasClass("scrollable") && me.parents(".scrollable-container").length !== 1) {
        return e.preventDefault();
      } else {

      }
    }), false);
    touch_event_start = void 0;
    $(selector).bind("touchstart", function(event) {
      return touch_event_start = event;
    });
    return $(selector).bind("touchmove", function(event) {
      var y_diff;
      y_diff = parseInt(event.originalEvent.pageY - touch_event_start.originalEvent.pageY);
      if (y_diff > height || (strictness && Math.abs(y_diff) > 5)) {
        event.preventDefault();
        return false;
      }
    });
  },
  saveJSONFile: function(filename, object) {
    var fail, _gotFileEntry, _write;
    fail = function(e) {
      return console.log(e);
    };
    _write = function(writer) {
      return writer.write(JSON.stringify(object));
    };
    _gotFileEntry = function(e) {
      return e.createWriter(_write, fail);
    };
    return carrall._fsroot.getFile(filename, {
      create: true,
      exclusive: false
    }, _gotFileEntry, fail);
  },
  loadJSONFile: function(filename, root, key, cb) {
    var fail, _gotFile, _gotFileEntry;
    fail = cb;
    _gotFile = function(file) {
      var reader;
      reader = new FileReader();
      reader.onloadend = function(evt) {
        var res;
        res = JSON.parse(evt.target.result);
        if (res) {
          root[key] = res;
        }
        return cb();
      };
      reader.onerror = function(e) {
        return console.log(e);
      };
      reader.readAsText(file);
      if (file.size === 0) {
        return cb();
      }
    };
    _gotFileEntry = function(e) {
      return e.file(_gotFile, fail);
    };
    return carrall._fsroot.getFile(filename, {
      create: true,
      exclusive: false
    }, _gotFileEntry, fail);
  },
  saveXML: function(path, dom, cb) {
    var fail, xml, _gotFileEntry, _write;
    xml = (new XMLSerializer()).serializeToString(dom[0]);
    fail = function(e) {
      return console.log(e);
    };
    _write = function(writer) {
      writer.onwriteend = cb;
      return writer.write(xml);
    };
    _gotFileEntry = function(e) {
      return e.createWriter(_write, fail);
    };
    path = path.replace(carrall._fsroot.fullPath + "/", "");
    console.log("Trying to save " + path);
    return carrall._fsroot.getFile(path, {
      create: true,
      exclusive: false
    }, _gotFileEntry, fail);
  },
  loadXML: function(path, cb, ecb) {
    var noncedPath;
    if (!path.match(/^file:\//)) {
      path = "file://" + path;
    }
    if (!ecb) {
      ecb = function(e) {
        return console.log(e);
      };
    }
    noncedPath = path + "?" + (new Date()).getTime();
    return $.ajax({
      url: noncedPath,
      method: "GET",
      dataType: "xml",
      error: ecb
    }).done(function(data) {
      return cb($(data));
    });
  }
};
