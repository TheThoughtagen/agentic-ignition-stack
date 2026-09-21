from starter import format_batch_status
from testing.assertions import assert_equal
from testing.decorators import test


@test
def formats_in_progress_batch_status():
	assert_equal(format_batch_status("DEMO-001", False), "Batch DEMO-001: In Progress")


@test
def formats_completed_batch_status():
	assert_equal(format_batch_status("DEMO-001", True), "Batch DEMO-001: Complete")
