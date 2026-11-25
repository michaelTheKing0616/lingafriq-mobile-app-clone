"""Build signed semver v2 content packs with hash-addressed blobs (P4-105)."""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content_pipeline.pack_signing import (
    PackSigningError,
    parse_semver,
    public_key_b64,
    resolve_private_key,
    sign_manifest,
    stable_stringify,
)

LEGACY_BUNDLE_DIRS: tuple[str, ...] = (
    "curriculum_bundle",
    "curriculum_expanded_bundle",
    "lingafriq_FINAL_curriculum",
    "lingafriq_full_curriculum_bundle",
)

HASH_FILENAME_RE = re.compile(r"^[0-9a-f]{64}\.[a-z0-9]+$")
_NON_ASCII_RE = re.compile(r"[^\x00-\x7F]")


class PackBuildError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class PackBlobInput:
    data: bytes
    ext: str


@dataclass(frozen=True)
class PackObjectInput:
    stable_id: str
    kind: str
    payload: Mapping[str, Any]


@dataclass
class BuiltPack:
    manifest: dict[str, Any]
    signature: str
    public_key: str
    files: dict[str, bytes]


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def blob_storage_name(data: bytes, ext: str) -> str:
    cleaned_ext = ext.strip().lstrip(".").lower()
    if not cleaned_ext or not re.fullmatch(r"[a-z0-9]+", cleaned_ext):
        raise PackBuildError("PACK_BLOB_INVALID", f"extension {ext!r} is invalid")
    name = f"{sha256_hex(data)}.{cleaned_ext}"
    assert_hash_filename(name)
    return name


def assert_hash_filename(name: str) -> None:
    if _NON_ASCII_RE.search(name):
        raise PackBuildError("PACK_FILENAME_INVALID", "blob filename must be ASCII")
    if not HASH_FILENAME_RE.match(name):
        raise PackBuildError(
            "PACK_FILENAME_INVALID",
            "filename must be 64-char hex content hash plus extension",
        )


def _nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def _iter_string_paths(value: Any, path: str) -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    if isinstance(value, str):
        found.append((path, value))
    elif isinstance(value, Mapping):
        for key, child in value.items():
            child_path = f"{path}.{key}" if path else str(key)
            found.extend(_iter_string_paths(child, child_path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.extend(_iter_string_paths(child, f"{path}[{index}]"))
    return found


def assert_nfc_normalized(obj: Mapping[str, Any]) -> None:
    for field_path, text in _iter_string_paths(obj, ""):
        if _nfc(text) != text:
            raise PackBuildError(
                "NFC_VIOLATION",
                f"string at {field_path or '<root>'} is not NFC-normalised",
            )


def normalize_object_strings(obj: Mapping[str, Any]) -> dict[str, Any]:
    assert_nfc_normalized(obj)
    return json.loads(json.dumps(obj, ensure_ascii=False), object_hook=_nfc_hook)


def _nfc_hook(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: _nfc_hook(child) for key, child in value.items()}
    if isinstance(value, list):
        return [_nfc_hook(child) for child in value]
    if isinstance(value, str):
        return _nfc(value)
    return value


def object_content_hash(payload: Mapping[str, Any]) -> str:
    body = stable_stringify(payload).encode("utf-8")
    return sha256_hex(body)


def object_storage_name(content_hash: str) -> str:
    name = f"{content_hash}.json"
    if not re.fullmatch(r"[0-9a-f]{64}\.json", name):
        raise PackBuildError("PACK_OBJECT_INVALID", "object hash filename invalid")
    return name


def _object_entries(objects: Sequence[PackObjectInput]) -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    seen_ids: set[str] = set()
    for obj in objects:
        if obj.stable_id in seen_ids:
            raise PackBuildError("PACK_OBJECT_INVALID", f"duplicate stable id {obj.stable_id}")
        seen_ids.add(obj.stable_id)
        normalized = normalize_object_strings(obj.payload)
        content_hash = object_content_hash(normalized)
        entries.append(
            {
                "stable_id": obj.stable_id,
                "kind": obj.kind,
                "sha256": content_hash,
            }
        )
    entries.sort(key=lambda row: row["stable_id"])
    return entries


def _blob_entries(blobs: Sequence[PackBlobInput]) -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    for blob in blobs:
        name = blob_storage_name(blob.data, blob.ext)
        entries.append({"path": f"blobs/{name}", "sha256": sha256_hex(blob.data)})
    entries.sort(key=lambda row: row["path"])
    return entries


def build_pack(
    version: str,
    objects: Sequence[PackObjectInput],
    blobs: Sequence[PackBlobInput],
    *,
    built_at: str,
    signing_seed_hex: str | None = None,
) -> BuiltPack:
    semver = version.strip()
    if not parse_semver(semver):
        raise PackBuildError("PACK_VERSION_INVALID", f"version must be semver, got {version!r}")

    private_key = resolve_private_key(signing_seed_hex)
    if private_key is None:
        raise PackSigningError("PACK_SIGNING_KEY_MISSING", "CONTENT_PACK_ED25519_SEED is not configured")

    object_rows = _object_entries(objects)
    blob_rows = _blob_entries(blobs)

    manifest: dict[str, Any] = {
        "format": "lingafriq.content_pack.v2",
        "version": semver,
        "built_at": built_at,
        "replaces_legacy_bundles": list(LEGACY_BUNDLE_DIRS),
        "objects": object_rows,
        "blobs": blob_rows,
    }

    public_key = public_key_b64(private_key.public_key())
    signature = sign_manifest(manifest, private_key)

    files: dict[str, bytes] = {
        "manifest.json": json.dumps(manifest, indent=2, ensure_ascii=False).encode("utf-8"),
        "public_key.txt": public_key.encode("ascii"),
        "signature.txt": signature.encode("ascii"),
    }

    for obj in objects:
        normalized = normalize_object_strings(obj.payload)
        content_hash = object_content_hash(normalized)
        rel = f"objects/{object_storage_name(content_hash)}"
        files[rel] = json.dumps(normalized, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    for blob in blobs:
        name = blob_storage_name(blob.data, blob.ext)
        files[f"blobs/{name}"] = blob.data

    return BuiltPack(manifest=manifest, signature=signature, public_key=public_key, files=files)


def verify_built_pack(pack: BuiltPack) -> PackBuildError | PackSigningError | None:
    from tools.content_pipeline.pack_signing import verify_pack_signature

    err = verify_pack_signature(pack.manifest, pack.signature, pack.public_key)
    if err is not None:
        return err

    for row in pack.manifest.get("objects", []):
        if not isinstance(row, Mapping):
            return PackBuildError("PACK_VERIFY_FAILED", "invalid object row")
        rel = f"objects/{object_storage_name(str(row['sha256']))}"
        data = pack.files.get(rel)
        if data is None:
            return PackBuildError("PACK_VERIFY_FAILED", f"missing object file {rel}")
        try:
            payload = json.loads(data.decode("utf-8"))
        except json.JSONDecodeError:
            return PackBuildError("PACK_VERIFY_FAILED", f"invalid json for {rel}")
        if object_content_hash(payload) != row["sha256"]:
            return PackBuildError("PACK_VERIFY_FAILED", f"content hash mismatch for {rel}")

    for row in pack.manifest.get("blobs", []):
        if not isinstance(row, Mapping):
            return PackBuildError("PACK_VERIFY_FAILED", "invalid blob row")
        rel = str(row["path"])
        data = pack.files.get(rel)
        if data is None:
            return PackBuildError("PACK_VERIFY_FAILED", f"missing blob file {rel}")
        if sha256_hex(data) != row["sha256"]:
            return PackBuildError("PACK_VERIFY_FAILED", f"hash mismatch for {rel}")
        assert_hash_filename(Path(rel).name)
    return None


def diff_manifests(
    old_manifest: Mapping[str, Any],
    new_manifest: Mapping[str, Any],
) -> dict[str, list[str]]:
    old_by_id = {
        str(row["stable_id"]): str(row["sha256"])
        for row in old_manifest.get("objects", [])
        if isinstance(row, Mapping) and "stable_id" in row and "sha256" in row
    }
    new_by_id = {
        str(row["stable_id"]): str(row["sha256"])
        for row in new_manifest.get("objects", [])
        if isinstance(row, Mapping) and "stable_id" in row and "sha256" in row
    }
    old_blob = {
        str(row["path"]): str(row["sha256"])
        for row in old_manifest.get("blobs", [])
        if isinstance(row, Mapping) and "path" in row and "sha256" in row
    }
    new_blob = {
        str(row["path"]): str(row["sha256"])
        for row in new_manifest.get("blobs", [])
        if isinstance(row, Mapping) and "path" in row and "sha256" in row
    }

    added: set[str] = set()
    removed: set[str] = set()
    changed: set[str] = set()

    for stable_id, new_hash in new_by_id.items():
        old_hash = old_by_id.get(stable_id)
        if old_hash is None:
            added.add(new_hash)
        elif old_hash != new_hash:
            changed.add(new_hash)
            removed.add(old_hash)

    for stable_id, old_hash in old_by_id.items():
        if stable_id not in new_by_id:
            removed.add(old_hash)

    for path, new_hash in new_blob.items():
        old_hash = old_blob.get(path)
        if old_hash is None:
            added.add(new_hash)
        elif old_hash != new_hash:
            changed.add(new_hash)
            removed.add(old_hash)

    for path, old_hash in old_blob.items():
        if path not in new_blob:
            removed.add(old_hash)

    return {
        "added": sorted(added),
        "removed": sorted(removed),
        "changed": sorted(changed),
    }


def _file_content_hash(path: str, data: bytes) -> str:
    if path.startswith("objects/") and path.endswith(".json"):
        payload = json.loads(data.decode("utf-8"))
        return object_content_hash(payload)
    return sha256_hex(data)


def apply_pack_diff(
    base_files: Mapping[str, bytes],
    diff: Mapping[str, Sequence[str]],
    additions: Mapping[str, bytes],
) -> dict[str, bytes]:
    result = dict(base_files)
    for digest in diff.get("removed", ()):
        to_delete = [
            path
            for path, data in result.items()
            if path not in ("manifest.json", "public_key.txt", "signature.txt")
            and _file_content_hash(path, data) == digest
        ]
        for path in to_delete:
            del result[path]
    for digest in list(diff.get("added", ())) + list(diff.get("changed", ())):
        matches = [path for path in additions if _file_content_hash(path, additions[path]) == digest]
        if not matches:
            raise PackBuildError("PACK_DIFF_APPLY_FAILED", f"missing bytes for hash {digest}")
        for path in matches:
            result[path] = additions[path]
    return result


def suggest_semver_bump(
    old_manifest: Mapping[str, Any],
    new_manifest: Mapping[str, Any],
) -> str:
    old_objects = {
        str(row["stable_id"]): str(row["sha256"])
        for row in old_manifest.get("objects", [])
        if isinstance(row, Mapping)
    }
    new_objects = {
        str(row["stable_id"]): str(row["sha256"])
        for row in new_manifest.get("objects", [])
        if isinstance(row, Mapping)
    }

    old_ids = set(old_objects)
    new_ids = set(new_objects)
    if old_ids - new_ids:
        return "major"
    if new_ids - old_ids:
        return "minor"

    for stable_id in old_ids & new_ids:
        if old_objects[stable_id] != new_objects[stable_id]:
            return "patch"

    old_blob_hashes = {
        str(row["sha256"])
        for row in old_manifest.get("blobs", [])
        if isinstance(row, Mapping)
    }
    new_blob_hashes = {
        str(row["sha256"])
        for row in new_manifest.get("blobs", [])
        if isinstance(row, Mapping)
    }
    if new_blob_hashes - old_blob_hashes:
        if old_blob_hashes - new_blob_hashes:
            return "major"
        return "minor"
    if old_blob_hashes != new_blob_hashes:
        return "patch"
    return "patch"
