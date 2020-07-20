
var panoId;
var panoLat;
var panoLong;

function getCurrentTabUrl(callback) {
  // Query filter to be passed to chrome.tabs.query - see
  // https://developer.chrome.com/extensions/tabs#method-query
  var queryInfo = {
    active: true,
    currentWindow: true
  };

  chrome.tabs.query(queryInfo, function(tabs) {
    var tab = tabs[0];
    var url = tab.url;
	var title = tab.title;
    console.assert(typeof url == 'string', 'tab.url should be a string');
    callback(url, title);
  });
}
function makeForm(url, title) {
  chrome.storage.sync.get("userid", function(items) {
    if (!chrome.runtime.error) {
      document.getElementById("userid").value = items.userid;
    }
  });
  document.getElementById("url").innerText = url;
  // If it's a street view pano
  if (url.includes("//www.google") && url.includes("/maps/") && url.includes("/data=")) {
	 document.getElementById("panodiv").style = "display: block;"
	 document.getElementById("sendbutton").innerText = "Send panorama";
	 document.getElementById("pagetype").innerText = "pano";
	 // extract pano ID
	 var p1 = url.indexOf("!1s") + 3;
	 var p2 = url.indexOf("!2e"); 
	 panoId = url.slice(p1, p2);
	 // extract lat and lon
	 panoLat = "";
	 panoLon = "";
	 p1 = url.indexOf("@");
	 if (p1 > -1) {
		 p1 += 1;
		 var s = url.slice(p1, -1);
		 p1 = s.indexOf(",");
		 panoLat = s.slice(0, p1);
		 s = s.slice(p1 + 1, -1);
		 p1 = s.indexOf(",");	
		 panoLon = s.slice(0, p1);
	 }
  }
  // else it's a bookmark
  else {
	 document.getElementById("bookmarkdiv").style = "display: block;"
	 document.getElementById("sendbutton").innerText = "Send bookmark";
	 document.getElementById("pagetype").innerText = "bookmark";
  }
  document.getElementById("description").value = title;
  chrome.storage.sync.get("titlecolor", function(items) {
    if (!chrome.runtime.error) {
      document.getElementById("titlecolor").value = items.titlecolor;
    }
  });    
  chrome.storage.sync.get("covercolor", function(items) {
    if (!chrome.runtime.error) {
      document.getElementById("covercolor").value = items.covercolor;
    }
  });  
  document.getElementById('sendbutton').addEventListener('click', sendUrlToObject);
  document.getElementById('options').addEventListener('click', openOptions);
}
function sendUrlToObject() {
	if (document.getElementById("userid").value == "") {
		//openOptions();
	} else {
		var xhr = new XMLHttpRequest();
		if (xhr == null){
			alert("Unable to create request");
		} else {	
			var userid = document.getElementById("userid").value.trim();
			if (userid.length == 0) {
				document.getElementById("statusdiv").style = "display: block;"
				document.getElementById("statustext").innerText = "Please enter your user ID";
				return false;
			}
			var url = document.getElementById("url").innerText;
			var pagetype  = document.getElementById("pagetype").innerText;
			if (pagetype == "bookmark") {
				var description = document.getElementById("description").value;
				var titlecolor = document.getElementById("titlecolor").value;
				var covercolor = document.getElementById("covercolor").value;
				var call = "http://www.rezmela.net/extint/v1/RecordUrl.php?" + 
					"uid=" + userid  + 
					"&url=" + url + 
					"&desc=" + encodeURIComponent(description) + 
					"&tcol=" + titlecolor +
					"&ccol=" + covercolor;
			}
			else if (pagetype == "pano") {
				var panodesc = document.getElementById("panodesc").value;
				var call = "http://www.rezmela.net/extint/v1/RecordPano.php?" + 
					"uid=" + userid  + 
					"&panoid=" + panoId +
					"&lat=" + panoLat +
					"&lon=" + panoLon +
					"&desc=" + encodeURIComponent(panodesc);
			}
			//alert(call);
			xhr.open("GET", call, false);
			xhr.send();
		}
		chrome.storage.sync.set({'userid': userid}, function() {});
		var savecolors = document.getElementById("pagetype").checked;
		if (savecolors) {
			chrome.storage.sync.set({titlecolor: titlecolor, covercolor: covercolor,}, function() {});
		}
	}
	window.close();
}
function openOptions() {
	chrome.runtime.openOptionsPage();
}
function renderStatus(statusText) {
  document.getElementById('status').textContent = statusText;
}
document.addEventListener('DOMContentLoaded', function() {
  getCurrentTabUrl(function(url, title) {
	makeForm(url, title);
  });
});

