#!/usr/bin/env python3
"""Create an ephemeral internal IdP + browser test user on a disposable CI Gateway.

No credentials or generated user-source files are printed or committed. The
login is scoped to the current Docker Compose gateway on loopback.
"""
import json
import os
import time
import urllib.error
import urllib.request


URL = os.environ["IGNITION_GATEWAY_URL"].rstrip("/")
USER = os.environ["IGNITION_USER"]
PASSWORD = os.environ["IGNITION_PASSWORD"]
with open("secrets/ignition-api-token", encoding="utf-8") as token_file:
    TOKEN = token_file.read().strip()
HEADERS = {"X-Ignition-API-Token": TOKEN}


def request(path, method="GET", data=None):
    headers = dict(HEADERS)
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(
        URL + path, data=json.dumps(data).encode() if data is not None else None,
        headers=headers, method=method,
    )
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.load(response)


def create_resource(kind, name, config):
    resource = [{
        "name": name, "collection": "core", "enabled": True,
        "description": "Ephemeral browser-test authentication; local CI only",
        "config": config,
    }]
    result = request("/data/api/v1/resources/ignition/" + kind, "POST", resource)
    if not result.get("success"):
        raise RuntimeError("Failed to create " + kind)


def main():
    if os.environ.get("CI") != "true" or URL not in (
        "http://127.0.0.1:8088", "http://localhost:8088"
    ):
        raise RuntimeError("Refusing to configure browser login outside local CI Gateway")
    if USER != "demo-ci":
        raise RuntimeError("CI browser user must be demo-ci")

    create_resource("user-source", "demo-ci", {
        "profile": {"type": "INTERNAL", "lockoutEnabled": True,
                    "lockoutAttempts": 5, "lockoutWindow": 15},
        "settings": {"passwordMinLength": 8},
    })
    create_resource("identity-provider", "demo-ci", {
        "profile": {"type": "internal"},
        "settings": {"userSource": "demo-ci", "authMethods": [{"type": "basic", "config": {}}],
                     "sessionInactivityTimeout": 30},
    })
    user = {
        "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "userName": USER, "password": PASSWORD,
    }
    for attempt in range(20):
        try:
            created = request("/data/api/v1/scim/demo-ci/v2/Users", "POST", user)
            break
        except urllib.error.HTTPError as exc:
            if exc.code not in (404, 503) or attempt == 19:
                raise
            time.sleep(2)
    if created.get("userName") != USER:
        raise RuntimeError("CI browser user provisioning failed")

    # The test user has no Gateway administrator role. Setting the default IdP
    # lets /data/app/login reach the ephemeral internal login, while API-token
    # automation retains its existing local-only permissions.
    security = request("/data/api/v1/resources/singleton/ignition/security-properties")
    if not security.get("signature"):
        raise RuntimeError("Gateway security resource lacks a signature")
    security["config"]["systemIdentityProvider"] = "demo-ci"
    security["config"]["systemAuthProfile"] = "demo-ci"
    update = [{key: security[key] for key in
               ("signature", "collection", "enabled", "description", "config")}]
    result = request("/data/api/v1/resources/ignition/security-properties", "PUT", update)
    if not result.get("success"):
        raise RuntimeError("Could not set CI Gateway login provider")

    # The demo Perspective project is guest-accessible; this validates the
    # Gateway's actual browser-login flow independently of its guest tests.
    print("Ephemeral CI identity provider and test user ready.")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as exc:
        # An API error body could echo a password. Never print it.
        print("CI login provisioning failed with HTTP", exc.code)
        raise SystemExit(1)
    except urllib.error.URLError:
        print("CI login provisioning failed: Gateway unreachable")
        raise SystemExit(1)
