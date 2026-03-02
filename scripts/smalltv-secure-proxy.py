#!/usr/bin/env python3
"""Token-protected local proxy for SmallTV endpoints."""

from __future__ import annotations

import argparse
import concurrent.futures
import ipaddress
import json
import os
import shutil
import socket
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Final
from urllib.error import URLError
from urllib.request import Request, urlopen

DEFAULT_HOST: Final[str] = "127.0.0.1"
DEFAULT_PORT: Final[int] = 18080
SMALLTV_MODEL: Final[str] = "SmallTV-Ultra"
SCAN_WORKERS: Final[int] = 64
SCAN_TIMEOUT_SECONDS: Final[float] = 0.6
HOP_BY_HOP_HEADERS: Final[set[str]] = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


def _parse_args() -> argparse.Namespace:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Token-protected SmallTV proxy."
    )
    parser.add_argument(
        "--token",
        type=str,
        help="Bearer token value. Falls back to SMALLTV_PROXY_TOKEN.",
    )
    parser.add_argument(
        "--host",
        type=str,
        help="Listen host. Falls back to SMALLTV_PROXY_HOST.",
    )
    parser.add_argument(
        "--port",
        type=int,
        help="Listen port. Falls back to SMALLTV_PROXY_PORT.",
    )
    parser.add_argument(
        "--device-ip",
        type=str,
        help="SmallTV IP. Falls back to SMALLTV_DEVICE_IP.",
    )
    return parser.parse_args()


def _read_required_value(arg_value: str | None, env_name: str) -> str:
    value: str = (arg_value or os.environ.get(env_name, "")).strip()
    if not value:
        raise ValueError(
            f"Missing value. Use --token or set {env_name}."
        )
    return value


def _read_str_value(
    arg_value: str | None, env_name: str, default: str
) -> str:
    raw_value: str = (arg_value or os.environ.get(env_name, "")).strip()
    if not raw_value:
        return default
    return raw_value


def _read_int_value(
    arg_value: int | None, env_name: str, default: int
) -> int:
    if arg_value is not None:
        return arg_value

    raw_value: str = os.environ.get(env_name, "").strip()
    if not raw_value:
        return default

    try:
        return int(raw_value)
    except ValueError as error:
        raise ValueError(
            f"Environment variable {env_name} must be an integer"
        ) from error


def _resolve_local_ip() -> str:
    sock: socket.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("8.8.8.8", 80))
        local_ip: str = sock.getsockname()[0]
    finally:
        sock.close()
    return local_ip


def _probe_smalltv(ip_address: str) -> str | None:
    request: Request = Request(f"http://{ip_address}/v.json", method="GET")
    try:
        with urlopen(request, timeout=SCAN_TIMEOUT_SECONDS) as response:
            payload_bytes: bytes = response.read()
    except (URLError, TimeoutError):
        return None

    try:
        payload: dict[str, str] = json.loads(payload_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None

    if payload.get("m") == SMALLTV_MODEL:
        return ip_address
    return None


def _auto_detect_device_ip() -> str:
    local_ip: str = _resolve_local_ip()
    network: ipaddress.IPv4Network = ipaddress.ip_network(
        f"{local_ip}/24", strict=False
    )
    candidates: list[str] = [
        str(host_ip) for host_ip in network.hosts() if str(host_ip) != local_ip
    ]

    print(f"Auto-detecting {SMALLTV_MODEL} on {network}...")

    found_ips: list[str] = []
    with concurrent.futures.ThreadPoolExecutor(
        max_workers=SCAN_WORKERS
    ) as executor:
        future_map: dict[
            concurrent.futures.Future[str | None], str
        ] = {
            executor.submit(_probe_smalltv, candidate_ip): candidate_ip
            for candidate_ip in candidates
        }
        for future in concurrent.futures.as_completed(future_map):
            result_ip: str | None = future.result()
            if result_ip is not None:
                found_ips.append(result_ip)

    found_ips.sort()
    if len(found_ips) == 1:
        detected_ip: str = found_ips[0]
        print(f"Detected SmallTV at {detected_ip}")
        return detected_ip

    if not found_ips:
        raise ValueError(
            "Could not auto-detect any SmallTV-Ultra on local /24. "
            "Run again with --device-ip <IP>."
        )

    formatted_ips: str = ", ".join(found_ips)
    raise ValueError(
        "Multiple SmallTV-Ultra devices detected: "
        f"{formatted_ips}. Run again with --device-ip <IP>."
    )


def _print_cloudflared_install_guidance() -> None:
    if shutil.which("cloudflared") is not None:
        return

    print("Warning: 'cloudflared' was not found in PATH.")
    print("To expose this proxy over the internet, install cloudflared first:")
    print("  macOS (Homebrew): brew install cloudflared")
    print("  Debian/Ubuntu: see https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/")
    print("  Windows (winget): winget install Cloudflare.cloudflared")
    print("After install, run:")
    print("  cloudflared tunnel --url http://127.0.0.1:18080")


class SmallTVProxyHandler(BaseHTTPRequestHandler):
    """Expose SmallTV API behind a bearer token."""

    token: str = ""
    upstream_base_url: str = ""

    def do_GET(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        if self.path == "/healthz":
            self._send_json(HTTPStatus.OK, {"status": "ok"})
            return

        self._proxy_request()

    def do_POST(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        self._proxy_request()

    def do_PUT(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        self._proxy_request()

    def do_PATCH(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        self._proxy_request()

    def do_DELETE(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        self._proxy_request()

    def do_HEAD(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        self._proxy_request()

    def do_OPTIONS(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        self._proxy_request()

    def _proxy_request(self) -> None:
        auth_header: str = self.headers.get("Authorization", "")
        expected_header: str = f"Bearer {self.token}"
        if auth_header != expected_header:
            self._send_json(HTTPStatus.UNAUTHORIZED, {"error": "unauthorized"})
            return

        self._forward_to_upstream()

    def _forward_to_upstream(self) -> None:
        upstream_url: str = f"{self.upstream_base_url}{self.path}"
        request_headers: dict[str, str] = self._build_upstream_headers()
        request_body: bytes | None = self._read_request_body()
        request: Request = Request(
            upstream_url,
            data=request_body,
            headers=request_headers,
            method=self.command,
        )
        try:
            with urlopen(request, timeout=5) as response:
                body: bytes = response.read()
                status: int = int(response.status)
                response_headers: list[tuple[str, str]] = list(
                    response.headers.items()
                )
        except URLError as error:
            self._send_json(
                HTTPStatus.BAD_GATEWAY,
                {"error": "upstream_unreachable", "detail": str(error)},
            )
            return

        self.send_response(status)
        for header_name, header_value in response_headers:
            if header_name.lower() in HOP_BY_HOP_HEADERS:
                continue
            self.send_header(header_name, header_value)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def _build_upstream_headers(self) -> dict[str, str]:
        headers: dict[str, str] = {}
        for header_name, header_value in self.headers.items():
            lowered_name: str = header_name.lower()
            if lowered_name in HOP_BY_HOP_HEADERS:
                continue
            if lowered_name in {"authorization", "host"}:
                continue
            headers[header_name] = header_value
        return headers

    def _read_request_body(self) -> bytes | None:
        if self.command in {"GET", "HEAD"}:
            return None
        content_length_raw: str = self.headers.get("Content-Length", "0")
        try:
            content_length: int = int(content_length_raw)
        except ValueError:
            content_length = 0
        if content_length <= 0:
            return None
        return self.rfile.read(content_length)

    def _send_json(self, status: HTTPStatus, payload: dict[str, str]) -> None:
        body: bytes = json.dumps(payload).encode("utf-8")
        self.send_response(int(status))
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:
        return


def main() -> None:
    args: argparse.Namespace = _parse_args()
    token: str = _read_required_value(args.token, "SMALLTV_PROXY_TOKEN")
    host: str = _read_str_value(args.host, "SMALLTV_PROXY_HOST", DEFAULT_HOST)
    port: int = _read_int_value(args.port, "SMALLTV_PROXY_PORT", DEFAULT_PORT)
    device_ip: str = _read_str_value(
        args.device_ip, "SMALLTV_DEVICE_IP", ""
    )
    if not device_ip:
        device_ip = _auto_detect_device_ip()
    upstream_base_url: str = f"http://{device_ip}"
    _print_cloudflared_install_guidance()

    SmallTVProxyHandler.token = token
    SmallTVProxyHandler.upstream_base_url = upstream_base_url

    print(f"Starting secure proxy on http://{host}:{port}")
    print(f"Forwarding authenticated requests to {upstream_base_url}")
    print("Health endpoint (no token): GET /healthz")

    server: ThreadingHTTPServer = ThreadingHTTPServer(
        (host, port), SmallTVProxyHandler
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
