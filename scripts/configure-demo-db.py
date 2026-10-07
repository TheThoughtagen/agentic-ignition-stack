#!/usr/bin/env python3
"""Provision only the local Storm demo JDBC connection via Ignition 8.3 API."""
import json
import os
import urllib.error
import urllib.request


def main():
    url = os.environ["IGNITION_GATEWAY_URL"].rstrip("/")
    token_path = os.path.join(os.path.dirname(__file__), "..", "secrets", "ignition-api-token")
    with open(token_path, encoding="utf-8") as handle:
        token = handle.read().strip()
    password = os.environ["DEMO_DB_PASSWORD"]

    def call(path, method="GET", payload=None, content_type="application/json"):
        headers = {"X-Ignition-API-Token": token}
        if payload is not None:
            headers["Content-Type"] = content_type
        req = urllib.request.Request(url + path, data=payload, headers=headers, method=method)
        with urllib.request.urlopen(req, timeout=15) as response:
            return json.load(response)

    path = "/data/api/v1/resources/list/ignition/database-connection"
    existing = call(path)
    for item in existing.get("items", []):
        if item["name"] == "storm_demo":
            health = item.get("healthchecks", {}).get("status", {}).get("result", {})
            if not health.get("healthy"):
                raise RuntimeError("Existing demo JDBC connection is unhealthy; inspect Gateway settings")
            print("Demo JDBC connection is healthy; not changing its secret.")
            return

    secret = call("/data/api/v1/encryption/encrypt", "POST", password.encode(), "text/plain")
    resource = [{
        "name": "storm_demo", "collection": "core", "enabled": True,
        "description": "Disposable Storm work-order demo database",
        "config": {
            "driver": "PostgreSQL", "translator": "POSTGRES",
            "connectURL": "jdbc:postgresql://postgres:5432/storm_demo",
            "username": "storm_demo", "password": {"type": "Embedded", "data": secret},
        },
    }]
    result = call("/data/api/v1/resources/ignition/database-connection", "POST", json.dumps(resource).encode())
    if not result.get("success"):
        raise RuntimeError("Gateway refused demo database resource")
    print("Created local demo JDBC connection.")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as exc:
        # Gateway error bodies can echo submitted secrets; show only the HTTP status.
        print("Demo JDBC setup failed with HTTP", exc.code)
        if "encryption/encrypt" in exc.url:
            print("Encryption endpoint rejected the credential request.")
        raise SystemExit(1)
    except urllib.error.URLError as exc:
        print("Demo JDBC setup failed: gateway unreachable")
        raise SystemExit(1)
