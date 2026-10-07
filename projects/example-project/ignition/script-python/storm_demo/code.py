"""Gateway-side CMMS -> PostgreSQL work-order triage (local Compose only)."""

API_URL = "http://work-orders-api:8090"
DATABASE = "storm_demo"


def classify(priority, status):
	"""Pure decision rule; deliberately easy to alter live and retest."""
	if status != "open":
		return "Closed"
	if priority == "high":
		return "Expedite"
	return "Queue"


def validate_id(order_id):
	"""Restrict both the external request path and the database key."""
	import re
	if not re.match(r"^WO-[0-9]{1,8}$", str(order_id)):
		raise ValueError("Expected work-order ID WO-<digits>")
	return str(order_id)


def fetch_order(order_id):
	"""Fetch one known work order over the Compose-internal network."""
	order_id = validate_id(order_id)
	response = system.net.httpClient(timeout=5000).get("{}/work-orders/{}".format(API_URL, order_id))
	if response.statusCode != 200:
		raise ValueError("CMMS request failed with HTTP {}".format(response.statusCode))
	order = system.util.jsonDecode(response.text)
	if order.get("id") != order_id:
		raise ValueError("CMMS response ID mismatch")
	return order


def ingest(order_id):
	"""Fetch external work order, then upsert the classified result in Postgres."""
	order = fetch_order(order_id)
	state = classify(order["priority"], order["status"])
	system.db.runPrepUpdate(
		"INSERT INTO work_order_triage "
		"(work_order_id, asset, priority, summary, source_status, triage_state) "
		"VALUES (?, ?, ?, ?, ?, ?) "
		"ON CONFLICT (work_order_id) DO UPDATE SET "
		"asset=EXCLUDED.asset, priority=EXCLUDED.priority, "
		"summary=EXCLUDED.summary, source_status=EXCLUDED.source_status, "
		"triage_state=EXCLUDED.triage_state, updated_at=NOW()",
		[order["id"], order["asset"], order["priority"], order["summary"],
		 order["status"], state], DATABASE
	)
	return get_order(order["id"])


def get_order(order_id):
	"""Read a persisted triage record by its validated identifier."""
	order_id = validate_id(order_id)
	rows = system.db.runPrepQuery(
		"SELECT work_order_id, asset, priority, summary, source_status, "
		"triage_state FROM work_order_triage WHERE work_order_id = ?",
		[order_id], DATABASE
	)
	if not rows:
		return None
	row = rows[0]
	return dict((key, str(row[key])) for key in (
		"work_order_id", "asset", "priority", "summary", "source_status", "triage_state"
	))
