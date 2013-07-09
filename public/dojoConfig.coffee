dojoConfig =
	parseOnLoad: true
	isDebug: true
	packages: [
		{name: "gotemb", location: location.pathname.replace(/\/[^\/]+$/, "") + "/gotemb"}
		{name: "eligrey", location: location.pathname.replace(/\/[^\/]+$/, "") + "/eligrey"}
	]
	async: true