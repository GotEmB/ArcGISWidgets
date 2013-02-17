dojoConfig =
	parseOnLoad: true
	isDebug: true
	packages: [
		name: "gotemb"
		location: location.pathname.replace(/\/[^\/]+$/, "") + "/gotemb"
	]
	async: true