def doPost(request, session):
	"""Explicit ingestion trigger; only the host-published local gateway reaches it."""
	params = request.get("params", {})
	order_id = params.get("id", "WO-1042")
	if isinstance(order_id, (list, tuple)):
		order_id = order_id[0]
	try:
		return {"json": {"order": storm_demo.ingest(str(order_id))}}
	except ValueError as exc:
		request["servletResponse"].setStatus(400)
		return {"json": {"error": str(exc)}}
