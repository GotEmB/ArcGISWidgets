dojoConfig =
	parseOnLoad: true
	isDebug: true
	packages: [
		{name: "gotemb", location: location.pathname.replace(/\/[^\/]+$/, "") + "/gotemb"}
		{name: "xstyle", location: "//dojofoundation.org/packages/dgrid/js/xstyle"}
		{name: "put-selector", location: "//dojofoundation.org/packages/dgrid/js/put-selector"}
		{name: "dgrid", location: "//dojofoundation.org/packages/dgrid/js/dgrid"}
		{name: "eligrey", location: location.pathname.replace(/\/[^\/]+$/, "") + "/eligrey"}
		{name: "socket.io", location: location.pathname.replace(/\/[^\/]+$/, "") + "/socket.io"}
	]
	async: true