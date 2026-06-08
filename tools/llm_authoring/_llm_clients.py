"""LLM client wrappers for the authoring pipeline.

Two providers are supported:

- **Anthropic Claude** (``CLAUDE_API_KEY`` / ``ANTHROPIC_API_KEY``) — used
  as the primary drafter (``claude-sonnet-4-5`` or env override).
- **OpenAI** (``OPENAI_API_KEY``) — used as the verifier
  (``gpt-5`` or env override).

Both clients enforce JSON outputs, apply bounded retries with
exponential backoff, and surface cost estimates for budgeting.

If the corresponding API key is missing, the client returns ``None``
from its ``call`` method instead of raising. This lets the pipeline
run offline / in CI on PRs from contributors without API access, while
still exercising the schema and validator paths.
"""

from __future__ import annotations

import json
import logging
import os
import time
from dataclasses import dataclass, field
from typing import Any

import requests

logger = logging.getLogger(__name__)


@dataclass
class LLMUsage:
    input_tokens: int = 0
    output_tokens: int = 0
    requests_made: int = 0
    requests_failed: int = 0
    cost_estimate_usd: float = 0.0


@dataclass
class LLMResponse:
    text: str
    usage: LLMUsage = field(default_factory=LLMUsage)
    provider: str = ""
    model: str = ""

    def parse_json(self) -> Any:
        text = self.text.strip()
        if text.startswith("```"):
            # Strip ```json fences if the model wraps its output.
            text = text.strip("`")
            if "\n" in text:
                first, rest = text.split("\n", 1)
                if first.strip().lower().startswith("json"):
                    text = rest
            text = text.strip("`").strip()
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            raise ValueError(
                f"LLM ({self.provider}/{self.model}) returned non-JSON output: "
                f"{exc.msg} at pos {exc.pos}.\n--- raw output ---\n{self.text}"
            ) from exc


def _retry_post(
    url: str,
    headers: dict[str, str],
    payload: dict[str, Any],
    *,
    timeout: float = 60.0,
    max_retries: int = 4,
    base_backoff: float = 1.5,
) -> dict[str, Any]:
    last_err: Exception | None = None
    for attempt in range(max_retries):
        try:
            resp = requests.post(url, headers=headers, json=payload, timeout=timeout)
            if resp.status_code in (429, 500, 502, 503, 504):
                raise RuntimeError(
                    f"Transient HTTP {resp.status_code}: {resp.text[:300]}"
                )
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            sleep_for = base_backoff ** (attempt + 1)
            logger.warning(
                "LLM call attempt %s/%s failed: %s — retrying in %.1fs",
                attempt + 1,
                max_retries,
                exc,
                sleep_for,
            )
            time.sleep(sleep_for)
    assert last_err is not None
    raise last_err


class ClaudeClient:
    """Minimal Anthropic Messages API client tuned for JSON drafting."""

    def __init__(
        self,
        model: str | None = None,
        api_key: str | None = None,
        api_url: str = "https://api.anthropic.com/v1/messages",
        anthropic_version: str = "2023-06-01",
    ) -> None:
        self.api_key = (
            api_key
            or os.environ.get("CLAUDE_API_KEY")
            or os.environ.get("ANTHROPIC_API_KEY")
        )
        self.model = model or os.environ.get(
            "LINGAFRIQ_CLAUDE_MODEL", "claude-sonnet-4-5"
        )
        self.api_url = api_url
        self.anthropic_version = anthropic_version
        self.usage = LLMUsage()

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key)

    def call(
        self,
        system_prompt: str,
        user_prompt: str,
        *,
        max_tokens: int = 4000,
        temperature: float = 0.4,
    ) -> LLMResponse | None:
        if not self.is_configured:
            logger.info("ClaudeClient not configured — skipping call.")
            return None
        payload = {
            "model": self.model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "system": system_prompt,
            "messages": [
                {"role": "user", "content": user_prompt},
            ],
        }
        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": self.anthropic_version,
            "content-type": "application/json",
        }
        self.usage.requests_made += 1
        try:
            data = _retry_post(self.api_url, headers, payload)
        except Exception as exc:  # noqa: BLE001
            self.usage.requests_failed += 1
            raise RuntimeError(f"Claude call failed: {exc}") from exc

        usage = data.get("usage", {}) or {}
        input_tokens = int(usage.get("input_tokens", 0))
        output_tokens = int(usage.get("output_tokens", 0))
        self.usage.input_tokens += input_tokens
        self.usage.output_tokens += output_tokens
        # Sonnet pricing as of 2025-Q4 — approximate. Override if needed.
        self.usage.cost_estimate_usd += (
            input_tokens / 1_000_000 * 3.0 + output_tokens / 1_000_000 * 15.0
        )

        content = data.get("content", [])
        text_parts = [
            block.get("text", "")
            for block in content
            if block.get("type") == "text"
        ]
        text = "\n".join(text_parts).strip()
        return LLMResponse(
            text=text,
            usage=self.usage,
            provider="anthropic",
            model=self.model,
        )


class OpenAIClient:
    """Minimal OpenAI Responses/Chat client tuned for JSON verification."""

    def __init__(
        self,
        model: str | None = None,
        api_key: str | None = None,
        api_url: str = "https://api.openai.com/v1/chat/completions",
    ) -> None:
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        self.model = model or os.environ.get("LINGAFRIQ_OPENAI_MODEL", "gpt-5")
        self.api_url = api_url
        self.usage = LLMUsage()

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key)

    def call(
        self,
        system_prompt: str,
        user_prompt: str,
        *,
        max_tokens: int = 4000,
        temperature: float = 0.2,
    ) -> LLMResponse | None:
        if not self.is_configured:
            logger.info("OpenAIClient not configured — skipping call.")
            return None
        payload = {
            "model": self.model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
        }
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        self.usage.requests_made += 1
        try:
            data = _retry_post(self.api_url, headers, payload)
        except Exception as exc:  # noqa: BLE001
            self.usage.requests_failed += 1
            raise RuntimeError(f"OpenAI call failed: {exc}") from exc

        usage = data.get("usage", {}) or {}
        input_tokens = int(usage.get("prompt_tokens", 0))
        output_tokens = int(usage.get("completion_tokens", 0))
        self.usage.input_tokens += input_tokens
        self.usage.output_tokens += output_tokens
        # GPT-5 indicative pricing; override via env if it changes.
        self.usage.cost_estimate_usd += (
            input_tokens / 1_000_000 * 2.5 + output_tokens / 1_000_000 * 10.0
        )

        choices = data.get("choices", [])
        if not choices:
            return LLMResponse(text="", usage=self.usage, provider="openai", model=self.model)
        text = choices[0].get("message", {}).get("content", "")
        return LLMResponse(
            text=text,
            usage=self.usage,
            provider="openai",
            model=self.model,
        )
