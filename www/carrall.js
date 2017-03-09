var module;

if (!module) {
  module = {};
}

module.exports = window.carrall = {
  fsTries: 0,
  setup: function(cb) {
    var where, _gotFS;
    _gotFS = function(fs) {
      if (fs.isDirectory) {
        carrall._fsroot = fs;
        return cb();
      } else if (carrall.fsTries < 5) {
        console.log("Didn't get fs object, trying again");
        carrall.fsTries++;
        return window.setTimeout((function() {
          return carrall.setup(cb);
        }), 500);
      } else {
        return alert("Failed to get file system object");
      }
    };
    $("label").each(function(k, l) {
      return $(l).html(carrall.localize(l.id.replace(/Label$/, "")));
    });
    if (window.cordova) {
      where = carrall.isIOS() ? cordova.file.dataDirectory : cordova.file.externalApplicationStorageDirectory;
      return window.resolveLocalFileSystemURL(where, _gotFS, _gotFS);
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
  isAndroid: function() {
    if (window.device && window.device.platform) {
      return device.platform === "Android" || device.platform === "amazon-fireos";
    } else {
      return /android/i.test(navigator.userAgent);
    }
  },
  hasInternetConnection: function() {
    if (carrall.isAndroid() && window.cordova && !navigator.connection) {
      alert("You need to install the org.apache.cordova.network-information plugin");
    }
    if (navigator.connection) {
      return navigator.connection.type !== Connection.NONE;
    } else {
      return navigator.onLine;
    }
  },
  hasDecentInternetConnection: function() {
    if (navigator.connection) {
      return navigator.connection.type === Connection.CELL_3G || navigator.connection.type === Connection.CELL_4G || navigator.connection.type === Connection.WIFI || navigator.connection.type === Connection.ETHERNET;
    } else {
      return navigator.onLine;
    }
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
    if (!lang) {
      return "en";
    }
    return lang;
  },
  localize: function(sid) {
    return Localisation.Strings[carrall.getSystemLanguage()][sid] || Localisation.Strings["en"][sid];
  },
  orientation: function() {
    if (window.innerWidth > window.innerHeight) {
      return "landscape";
    } else {
      return "portrait";
    }
  },
  getPhonegapPath: function() {
    var path, phoneGapPath;
    path = window.location.pathname;
    phoneGapPath = path.substring(0, path.lastIndexOf('/') + 1);
    return phoneGapPath;
  },
  rerootPathUnderApp: function(path) {
    var newUID, newUIDm;
    if (!window.cordova || !carrall.isIOS()) {
      return path;
    }
    newUIDm = cordova.file.applicationStorageDirectory.match(/.*\/([0-9A-F-]{8,})/);
    if (newUIDm) {
      newUID = newUIDm[1];
      return path.replace(/(.*\/)[0-9A-F-]{8,}\//, "$1" + newUID + "/");
    }
    return path;
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
    if (!window.cordova) {
      return;
    }
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
  saveJSONFile: function(filename, object, replacer) {
    var fail, _gotFileEntry, _write;
    if (!window.cordova) {
      window.localStorage.setItem(filename, JSON.stringify(object, replacer));
      return;
    }
    fail = function(e) {
      return console.log(e);
    };
    _write = function(writer) {
      return writer.write(JSON.stringify(object, replacer));
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
    var data, fail, _gotFile, _gotFileEntry;
    fail = cb;
    if (!window.cordova) {
      data = window.localStorage.getItem(filename);
      if (data) {
        root[key] = JSON.parse(data);
      }
      return cb();
    }
    _gotFile = function(file) {
      var reader;
      reader = new FileReader();
      reader.onloadend = function(evt) {
        var res;
        try {
          res = JSON.parse(evt.target.result);
        } catch (_error) {

        }
        if (res) {
          root[key] = res;
        }
        return cb();
      };
      reader.onerror = function(e) {
        return console.log(e);
      };
      return reader.readAsText(file);
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
    if (!window.cordova) {
      window.localStorage.setItem(path, xml);
      return cb();
    }
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
    var data, noncedPath;
    if (!window.cordova) {
      data = window.localStorage.getItem(path);
      if (data) {
        return cb($data);
      }
      return ecb();
    }
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
