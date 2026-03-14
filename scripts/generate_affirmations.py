#!/usr/bin/env python3
"""
Generate ~18,252 static affirmations (4,563 per category) using Claude claude-opus-4-6.
Outputs: FocusOnYourself/Resources/affirmations.json
"""

import json
import os
import random
import anthropic

CATEGORIES = ["confidence", "health", "relationships", "mindfulness"]
TARGET_PER_CATEGORY = 4563
CALLS_PER_CATEGORY = 10
PER_CALL = 500

CATEGORY_THEMES = {
    "confidence": "Confidence & Self-Worth",
    "health": "Health & Body",
    "relationships": "Relationships & Love",
    "mindfulness": "Mindfulness & Calm",
}

OUTPUT_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "FocusOnYourself",
    "Resources",
    "affirmations.json",
)


def fetch_affirmations(client: anthropic.Anthropic, category: str, batch_num: int) -> list[str]:
    theme = CATEGORY_THEMES[category]
    prompt = (
        f"Write {PER_CALL} unique, short, powerful daily affirmations on the theme: {theme}. "
        "Use first person (\"I am\", \"I have\", \"I choose\", \"I feel\", \"I trust\", etc.). "
        "Each affirmation should be 1-2 sentences max. "
        f"Batch {batch_num + 1} of {CALLS_PER_CATEGORY} — make these distinct from previous batches. "
        "Format as a numbered list (1. ... 2. ... etc.), one affirmation per line. "
        "Return only the affirmation texts, no explanations or headers."
    )

    message = client.messages.create(
        model="claude-opus-4-6",
        max_tokens=8192,
        messages=[{"role": "user", "content": prompt}],
    )

    text = message.content[0].text
    lines = text.splitlines()
    results = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        # Remove leading "123. " numbering
        import re
        cleaned = re.sub(r"^\d+\.\s*", "", stripped)
        if cleaned:
            results.append(cleaned)
    return results


def main():
    client = anthropic.Anthropic()
    all_affirmations = []

    for category in CATEGORIES:
        print(f"\n[{category}] Generating affirmations...")
        seen: set[str] = set()
        collected: list[str] = []

        for i in range(CALLS_PER_CATEGORY):
            print(f"  Call {i + 1}/{CALLS_PER_CATEGORY}...", end=" ", flush=True)
            try:
                batch = fetch_affirmations(client, category, i)
                new_count = 0
                for a in batch:
                    normalized = a.lower().strip()
                    if normalized not in seen:
                        seen.add(normalized)
                        collected.append(a)
                        new_count += 1
                print(f"got {len(batch)}, {new_count} new (total: {len(collected)})")
            except Exception as e:
                print(f"ERROR: {e}")

        # Shuffle and trim to target
        random.shuffle(collected)
        trimmed = collected[:TARGET_PER_CATEGORY]
        print(f"  Final count for '{category}': {len(trimmed)}")

        for quote in trimmed:
            all_affirmations.append({"quote": quote, "category": category})

    # Shuffle the final list
    random.shuffle(all_affirmations)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(all_affirmations, f, ensure_ascii=False, indent=2)

    print(f"\nDone! Wrote {len(all_affirmations)} affirmations to {OUTPUT_PATH}")

    # Summary by category
    from collections import Counter
    counts = Counter(a["category"] for a in all_affirmations)
    for cat, count in sorted(counts.items()):
        print(f"  {cat}: {count}")


if __name__ == "__main__":
    main()
