#!/usr/bin/env python3
"""P11-038: CharacterSM L1–L5 layer isolation — keyed (objectId, propertyKey) must not overlap."""
from __future__ import annotations

import argparse
import json
import struct
import sys
import tempfile
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict, Dict, Iterable, List, Set, Tuple

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RIV = ROOT / "assets" / "rive" / "lingafriq_cast.riv"
CONTRACT = ROOT / "assets" / "rive" / "lingafriq_cast.contract.json"

L1_L5: Tuple[str, ...] = (
    "L1 Body",
    "L2 Face",
    "L3 Gaze/Head",
    "L4 Blink",
    "L5 Mouth",
)

Keyed = Tuple[int, int]

TYPE_LINEAR_ANIMATION = 31
TYPE_KEYED_OBJECT = 25
TYPE_KEYED_PROPERTY = 26
TYPE_STATE_MACHINE_LAYER = 53
TYPE_ANIMATION_STATE = 61
TYPE_BLEND_ANIMATION = 64

PK_ANIMATION_NAME = 55
PK_OBJECT_ID = 51
PK_PROPERTY_KEY = 53
PK_ANIMATION_ID = 149
PK_BLEND_ANIMATION_ID = 165

FIELD_UINT, FIELD_STR, FIELD_FLOAT, FIELD_COLOR = 0, 1, 2, 3


def read_varuint(data: bytes, pos: int) -> tuple[int, int]:
    result = 0
    shift = 0
    while pos < len(data):
        byte = data[pos]
        pos += 1
        result |= (byte & 0x7F) << shift
        if (byte & 0x80) == 0:
            return result, pos
        shift += 7
        if shift > 35:
            raise ValueError("varuint too long")
    raise ValueError("unexpected end of riv while reading varuint")


def read_string(data: bytes, pos: int) -> tuple[str, int]:
    length, pos = read_varuint(data, pos)
    end = pos + length
    return data[pos:end].decode("utf-8", "replace"), end


def read_uint32(data: bytes, pos: int) -> tuple[int, int]:
    return struct.unpack_from("<I", data, pos)[0], pos + 4


def read_float32(data: bytes, pos: int) -> tuple[float, int]:
    return struct.unpack_from("<f", data, pos)[0], pos + 4


def read_header(data: bytes) -> tuple[int, Dict[int, int]]:
    pos = 4
    _, pos = read_varuint(data, pos)
    _, pos = read_varuint(data, pos)
    _, pos = read_varuint(data, pos)
    keys: List[int] = []
    while True:
        key, pos = read_varuint(data, pos)
        if key == 0:
            break
        keys.append(key)
    toc: Dict[int, int] = {}
    current_int = 0
    current_bit = 8
    for key in keys:
        if current_bit == 8:
            current_int, pos = read_uint32(data, pos)
            current_bit = 0
        toc[key] = (current_int >> current_bit) & 3
        current_bit += 2
    return pos, toc


def read_property_value(data: bytes, pos: int, field_index: int) -> tuple[object, int]:
    if field_index == FIELD_UINT:
        return read_varuint(data, pos)
    if field_index == FIELD_STR:
        return read_string(data, pos)
    if field_index == FIELD_FLOAT:
        return read_float32(data, pos)
    return read_uint32(data, pos)


def layer_name_in_blob(blob: bytes) -> str | None:
    for name in L1_L5:
        if name.encode("utf-8") in blob:
            return name
    return None


def load_contract_layer_tokens() -> Dict[str, List[str]]:
    if not CONTRACT.is_file():
        raise ValueError(f"missing contract: {CONTRACT}")
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    ownership = data.get("layerOwnership") or {}
    out: Dict[str, List[str]] = {}
    for layer in L1_L5:
        raw = ownership.get(layer)
        if not isinstance(raw, str):
            out[layer] = []
            continue
        tokens = [part.strip() for part in raw.split(",") if part.strip()]
        out[layer] = tokens
    return out


def find_token_overlaps(layer_tokens: Dict[str, List[str]]) -> List[str]:
    owner: Dict[str, str] = {}
    errors: List[str] = []
    for layer in L1_L5:
        for token in layer_tokens.get(layer, []):
            key = token.casefold()
            prev = owner.get(key)
            if prev is not None and prev != layer:
                errors.append(
                    f"layer ownership token {token!r} listed on {prev!r} and {layer!r}"
                )
            elif prev is None:
                owner[key] = layer
    return errors


def parse_riv(path: Path) -> tuple[list[Set[Keyed]], Dict[str, Set[Keyed]]]:
    data = path.read_bytes()
    if data[:4] != b"RIVE":
        raise ValueError(f"{path}: missing RIVE magic")

    pos, toc = read_header(data)
    animations: list[Set[Keyed]] = []
    current_anim: Set[Keyed] | None = None
    current_object_id: int | None = None

    current_layer: str | None = None
    layer_keys: DefaultDict[str, Set[Keyed]] = defaultdict(set)
    anim_layers: DefaultDict[int, Set[str]] = defaultdict(set)

    while pos < len(data):
        start = pos
        object_type, pos = read_varuint(data, pos)
        if object_type == 0:
            continue

        props: Dict[int, object] = {}
        while True:
            property_key, pos = read_varuint(data, pos)
            if property_key == 0:
                break
            field_index = toc.get(property_key, FIELD_UINT)
            value, pos = read_property_value(data, pos, field_index)
            props[property_key] = value

        blob = data[start:pos]
        if object_type == TYPE_STATE_MACHINE_LAYER:
            layer = layer_name_in_blob(blob)
            if layer is not None:
                current_layer = layer

        if object_type == TYPE_LINEAR_ANIMATION:
            current_anim = set()
            animations.append(current_anim)
            current_object_id = None
        elif object_type == TYPE_KEYED_OBJECT:
            oid = props.get(PK_OBJECT_ID)
            current_object_id = int(oid) if isinstance(oid, int) else None
        elif (
            object_type == TYPE_KEYED_PROPERTY
            and current_anim is not None
            and current_object_id is not None
        ):
            pk = props.get(PK_PROPERTY_KEY)
            if isinstance(pk, int):
                keyed: Keyed = (current_object_id, pk)
                current_anim.add(keyed)
        elif current_layer in L1_L5:
            anim_id: int | None = None
            if object_type == TYPE_ANIMATION_STATE:
                raw = props.get(PK_ANIMATION_ID)
                anim_id = int(raw) if isinstance(raw, int) else None
            elif object_type == TYPE_BLEND_ANIMATION:
                raw = props.get(PK_BLEND_ANIMATION_ID)
                anim_id = int(raw) if isinstance(raw, int) else None
            if anim_id is not None and 0 <= anim_id < len(animations):
                anim_layers[anim_id].add(current_layer)

    for anim_id, layers in anim_layers.items():
        if len(layers) != 1:
            continue
        layer = next(iter(layers))
        layer_keys[layer] |= animations[anim_id]

    return animations, dict(layer_keys)


def format_key(keyed: Keyed) -> str:
    return f"object={keyed[0]} property={keyed[1]}"


def find_overlaps(layer_keys: Dict[str, Set[Keyed]], layers: Iterable[str]) -> List[str]:
    owner: Dict[Keyed, str] = {}
    errors: List[str] = []
    for layer in layers:
        for keyed in layer_keys.get(layer, set()):
            prev = owner.get(keyed)
            if prev is not None and prev != layer:
                errors.append(
                    f"layer isolation: {format_key(keyed)} keyed by {prev!r} and {layer!r}"
                )
            elif prev is None:
                owner[keyed] = layer
    return errors


def analyze(path: Path) -> Dict[str, List[str]]:
    contract_tokens = load_contract_layer_tokens()
    _, layer_keys = parse_riv(path)
    listing: Dict[str, List[str]] = {}
    for layer in L1_L5:
        riv_keys = sorted(format_key(k) for k in layer_keys.get(layer, set()))
        spec = [f"spec:{token}" for token in contract_tokens.get(layer, [])]
        listing[layer] = spec + riv_keys
    return listing


def run_gate(path: Path) -> List[str]:
    errors: List[str] = []
    if not path.is_file():
        return [f"missing riv: {path}"]
    try:
        layer_tokens = load_contract_layer_tokens()
    except ValueError as exc:
        return [str(exc)]

    errors.extend(find_token_overlaps(layer_tokens))

    try:
        _, layer_keys = parse_riv(path)
    except ValueError as exc:
        return errors + [str(exc)]

    riv_bytes = path.read_bytes()
    for layer in L1_L5:
        if layer.encode("utf-8") not in riv_bytes:
            errors.append(f"{path.name}: missing state-machine layer name {layer!r}")
        if not layer_tokens.get(layer):
            errors.append(f"{layer!r}: missing layerOwnership in contract")

    errors.extend(find_overlaps(layer_keys, L1_L5))
    return errors


def self_test() -> List[str]:
    errors: List[str] = []

    token_overlap = find_token_overlaps(
        {"L1 Body": ["Body y"], "L2 Face": ["Body y", "brows"]},
    )
    if len(token_overlap) != 1:
        errors.append("self-test: expected one token overlap")

    keyed_overlap = find_overlaps(
        {"L1 Body": {(1, 10)}, "L2 Face": {(1, 10)}},
        L1_L5,
    )
    if len(keyed_overlap) != 1:
        errors.append("self-test: expected one keyed overlap")

    if find_overlaps(
        {"L1 Body": {(1, 10)}, "L2 Face": {(2, 11)}},
        L1_L5,
    ):
        errors.append("self-test: disjoint keyed layers should pass")

    if not DEFAULT_RIV.is_file():
        errors.append("self-test: production riv missing")
        return errors

    gate_errors = run_gate(DEFAULT_RIV)
    if gate_errors:
        errors.append(f"self-test: production gate failed: {gate_errors[0]}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gate", action="store_true", help="CI gate on lingafriq_cast.riv")
    parser.add_argument("--list", action="store_true", help="print keyed properties per L1–L5 layer")
    parser.add_argument("--riv", type=Path, default=DEFAULT_RIV)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--json", action="store_true", help="with --list, emit JSON")
    args = parser.parse_args()

    if args.self_test:
        failures = self_test()
        if failures:
            for item in failures:
                print(f"LAYER_ISOLATION_SELF_TEST_FAIL: {item}", file=sys.stderr)
            return 1
        print("check_layer_isolation: self-test ok")
        return 0

    if args.list:
        listing = analyze(args.riv)
        if args.json:
            print(json.dumps(listing, indent=2))
        else:
            for layer in L1_L5:
                print(f"## {layer}")
                for line in listing[layer]:
                    print(f"  {line}")
        return 0

    if args.gate:
        failures = run_gate(args.riv)
        if failures:
            for item in failures:
                print(f"LAYER_ISOLATION_FAIL: {item}", file=sys.stderr)
            return 1
        print("check_layer_isolation: ok")
        return 0

    parser.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
