def doPost(request, session):
	"""Run unit and API+database integration checks on the Gateway."""
	results = storm_tests.run()
	if results["failed"] or results["errors"]:
		request["servletResponse"].setStatus(207)
	return {"json": results}
