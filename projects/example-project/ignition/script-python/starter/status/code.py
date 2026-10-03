"""Small, dependency-free functions used by the starter's gateway tests."""


def format_batch_status(batch_id, is_complete):
	"""Return a stable display value for a sample batch."""
	state = "Complete" if is_complete else "In Progress"
	return "Batch {}: {}".format(batch_id, state)
