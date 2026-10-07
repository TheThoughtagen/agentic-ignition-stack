def doGet(request, session):
	"""Read-only status; for the local demo gateway, never expose publicly."""
	params = request.get("params", {})
	order_id = params.get("id", "WO-1042")
	if isinstance(order_id, (list, tuple)):
		order_id = order_id[0]
	try:
		order = storm_demo.get_order(str(order_id))
		return {"json": {"order": order}}
	except ValueError as exc:
		request["servletResponse"].setStatus(400)
		return {"json": {"error": str(exc)}}
