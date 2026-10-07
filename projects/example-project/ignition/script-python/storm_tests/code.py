"""Flat gateway-side work-order tests, discovered by storm-tests WebDev route."""


def run():
	"""Run seven gateway-native unit and cross-service assertions."""
	results = []
	def check(name, actual, expected):
		"""Record a named comparison for the gateway response."""
		results.append({"name": name, "passed": actual == expected})
	check("high priority", storm_demo.classify("high", "open"), "Expedite")
	check("low priority", storm_demo.classify("low", "open"), "Queue")
	check("closed order", storm_demo.classify("high", "closed"), "Closed")
	try:
		storm_demo.validate_id("../1042")
		results.append({"name": "reject unsafe ID", "passed": False})
	except ValueError:
		results.append({"name": "reject unsafe ID", "passed": True})
	check("external CMMS", storm_demo.fetch_order("WO-1042")["asset"], "Mixer-7")
	order = storm_demo.ingest("WO-1042")
	check("persist to Postgres", order["triage_state"], "Expedite")
	check("read from Postgres", storm_demo.get_order("WO-1042")["asset"], "Mixer-7")
	passed = sum(1 for result in results if result["passed"])
	return {"total": len(results), "passed": passed, "failed": len(results) - passed,
		"errors": 0, "results": results}
