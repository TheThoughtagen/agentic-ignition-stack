def doGet(request, session):
	"""Return usage information for the test runner endpoint.

	GET /data/testing/run - shows this help
	GET /data/testing/run?discover=true - lists discovered test modules
	"""
	params = request.get("params", {})
	discover = "discover" in params

	if discover:
		try:
			modules = testing.runner._discover_test_modules()
			return {"json": {
				"discovered_modules": modules,
				"count": len(modules),
			}}
		except Exception as e:
			import traceback
			return {"json": {
				"error": str(e),
				"traceback": traceback.format_exc(),
			}}

	return {"json": {
		"name": "example-project — Test Runner",
		"usage": {
			"run_all": "POST /data/testing/run",
			"run_module": "POST /data/testing/run?module=core.mes.changeover.__tests__",
			"run_package": "POST /data/testing/run?package=core.mes",
			"formats": "Add ?format=json|junit|text",
			"discover": "GET /data/testing/run?discover=true",
		},
	}}