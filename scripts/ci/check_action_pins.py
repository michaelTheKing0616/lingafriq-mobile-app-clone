#!/usr/bin/env python3
"""Delegate to check_pinned_actions.py so the older workflow path stays one checker."""

import runpy
from pathlib import Path

runpy.run_path(str(Path(__file__).with_name("check_pinned_actions.py")), run_name="__main__")
