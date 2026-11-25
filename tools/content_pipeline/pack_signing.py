"""Ed25519 signing for v2 content packs (P4-105)."""

from __future__ import annotations

import base64
import os
import re
from typing import Any, Mapping

SEMVER_PATTERN = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$")

try:
    from cryptography.hazmat.primitives.asymmetric.ed25519 import (
        Ed25519PrivateKey,
        Ed25519PublicKey,
    )
except ImportError:  # pragma: no cover - exercised when dependency missing
    Ed25519PrivateKey = None  # type: ignore[misc, assignment]
    Ed25519PublicKey = None  # type: ignore[misc, assignment]


class PackSigningError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _require_crypto() -> None:
    if Ed25519PrivateKey is None:
        raise PackSigningError(
            "PACK_SIGNING_UNAVAILABLE",
            "cryptography package is required for ed25519 pack signing",
        )


def parse_semver(version: str) -> bool:
    return bool(SEMVER_PATTERN.match(version.strip()))


def stable_stringify(value: Any) -> str:
    import json

    if value is None or not isinstance(value, (dict, list)):
        return json.dumps(value, separators=(",", ":"), ensure_ascii=False)
    if isinstance(value, list):
        return "[" + ",".join(stable_stringify(entry) for entry in value) + "]"
    record = value
    keys = sorted(record.keys())
    body = ",".join(
        json.dumps(key, ensure_ascii=False) + ":" + stable_stringify(record[key]) for key in keys
    )
    return "{" + body + "}"


def manifest_signing_bytes(manifest: Mapping[str, Any]) -> bytes:
    return stable_stringify(dict(manifest)).encode("utf-8")


def generate_keypair() -> tuple[Ed25519PrivateKey, Ed25519PublicKey]:
    _require_crypto()
    private_key = Ed25519PrivateKey.generate()
    return private_key, private_key.public_key()


def public_key_b64(public_key: Ed25519PublicKey) -> str:
    raw = public_key.public_bytes_raw()
    return base64.b64encode(raw).decode("ascii")


def load_private_key_from_seed_hex(seed_hex: str) -> Ed25519PrivateKey:
    _require_crypto()
    cleaned = seed_hex.strip()
    try:
        seed = bytes.fromhex(cleaned)
    except ValueError as exc:
        raise PackSigningError("PACK_SIGNING_KEY_INVALID", "seed must be hex") from exc
    if len(seed) != 32:
        raise PackSigningError("PACK_SIGNING_KEY_INVALID", "ed25519 seed must be 32 bytes")
    return Ed25519PrivateKey.from_private_bytes(seed)


def resolve_private_key(explicit_seed_hex: str | None = None) -> Ed25519PrivateKey | None:
    if isinstance(explicit_seed_hex, str) and explicit_seed_hex.strip():
        return load_private_key_from_seed_hex(explicit_seed_hex)
    from_env = os.environ.get("CONTENT_PACK_ED25519_SEED", "").strip()
    if from_env:
        return load_private_key_from_seed_hex(from_env)
    return None


def sign_manifest(manifest: Mapping[str, Any], private_key: Ed25519PrivateKey) -> str:
    signature = private_key.sign(manifest_signing_bytes(manifest))
    return base64.b64encode(signature).decode("ascii")


def verify_manifest_signature(
    manifest: Mapping[str, Any],
    signature_b64: str,
    public_key: Ed25519PublicKey,
) -> bool:
    try:
        signature = base64.b64decode(signature_b64.encode("ascii"), validate=True)
    except Exception:
        return False
    try:
        public_key.verify(signature, manifest_signing_bytes(manifest))
    except Exception:
        return False
    return True


def verify_pack_signature(
    manifest: Mapping[str, Any],
    signature_b64: str,
    public_key_b64: str,
) -> PackSigningError | None:
    _require_crypto()
    try:
        raw = base64.b64decode(public_key_b64.encode("ascii"), validate=True)
        public_key = Ed25519PublicKey.from_public_bytes(raw)
    except Exception:
        return PackSigningError("PACK_SIGNATURE_INVALID", "public key is invalid")
    if not verify_manifest_signature(manifest, signature_b64, public_key):
        return PackSigningError("PACK_SIGNATURE_INVALID", "manifest signature mismatch")
    return None
