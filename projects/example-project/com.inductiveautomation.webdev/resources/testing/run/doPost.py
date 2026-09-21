def doPost(request, session):
	"""Run tests and return JSON results.

	Query params:
		module  - Dotted module path to run specific tests
		         (e.g. "core.mes.changeover.__tests__")
		package - Dotted package prefix to filter
		         (e.g. "core.mes")
		format  - Output format: "json" (default), "junit", "text"

	POST body (JSON, optional):
		{"module": "...", "package": "...", "format": "..."}

	Returns:
		200 if all tests pass
		207 if there are failures or errors
		500 on runner error
	"""
	import json

	# Parse params from query string or POST body
	module = None
	package = ""
	fmt = "json"

	params = request.get("params", {})
	if params:
		module = _get_param(params, "module")
		package = _get_param(params, "package") or ""
		fmt = _get_param(params, "format") or "json"

	# Also check POST body
	body = request.get("data", None)
	if body:
		try:
			if hasattr(body, 'read'):
				body = body.read()
			body_data = json.loads(body)
			if isinstance(body_data, dict):
				module = body_data.get("module", module)
				package = body_data.get("package", package)
				fmt = body_data.get("format", fmt)
		except Exception:
			pass  # Fall through to query string params if body is not valid JSON

	try:
		if module:
			results = testing.runner.run_module(module)
			# Wrap single module in the run_all structure
			results = {
				"passed": results["passed"],
				"failed": results["failed"],
				"skipped": results["skipped"],
				"errors": results["errors"],
				"total": results["passed"] + results["failed"] + results["skipped"] + results["errors"],
				"duration_ms": results["duration_ms"],
				"modules": [results],
			}
		else:
			results = testing.runner.run_all(base_package=package)

		if fmt == "junit":
			xml = testing.reporter.to_junit_xml(results)
			return {
				"html": xml,
				"content-type": "application/xml",
			}
		elif fmt == "text":
			text = testing.reporter.to_console(results)
			return {
				"html": "<pre>%s</pre>" % text,
				"content-type": "text/plain",
			}

		# Default JSON
		status = 200 if results["failed"] == 0 and results["errors"] == 0 else 207
		request['servletResponse'].setStatus(status)
		return {"json": results}

	except Exception as e:
		import traceback
		return {"json": {
			"error": str(e),
			"traceback": traceback.format_exc(),
		}}


def _get_param(params, key):
	"""Extract a single query param value from Ignition WebDev params.

	Ignition WebDev params are Java String[] arrays. Indexing [0] on a
	plain string returns the first character, so we must check the type.
	"""
	val = params.get(key)
	if val is None:
		return None
	# Convert to string first — handles Java String and Python str
	s = str(val)
	# Java String[] arrays stringify as '[value]', plain strings don't
	# The safest check: if it looks like an array, use .toString() on element
	try:
		# Try treating as a Java array — getClass().isArray() works in Jython
		if hasattr(val, 'getClass') and val.getClass().isArray():
			from java.lang.reflect import Array
			if Array.getLength(val) > 0:
				return str(Array.get(val, 0))
			return None
	except Exception:
		pass
	# If it's a Python list/tuple, take first element
	if isinstance(val, (list, tuple)):
		return str(val[0]) if val else None
	# Already a string
	return s