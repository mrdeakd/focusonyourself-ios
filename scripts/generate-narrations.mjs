#!/usr/bin/env node
// One-time script to pre-generate all narration MP3s via ElevenLabs API.
// Run: ELEVENLABS_API_KEY=xxx node scripts/generate-narrations.mjs

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

const MEDITATIONS_PATH = path.join(ROOT, "FocusOnYourself/Resources/meditations.json");
const OUTPUT_DIR = path.join(ROOT, "FocusOnYourself/Resources/Narrations");
const MAP_PATH = path.join(ROOT, "FocusOnYourself/Resources/narration_map.json");

const VOICE_ID = "EXAVITQu4vr4xnSDxMaL"; // Sarah (free premade voice)
const MODEL_ID = "eleven_turbo_v2_5";
const VOICE_SETTINGS = { stability: 0.5, similarity_boost: 0.75 };

const API_KEY = process.env.ELEVENLABS_API_KEY;
if (!API_KEY) {
  console.error("Error: ELEVENLABS_API_KEY environment variable is not set.");
  process.exit(1);
}

fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const meditations = JSON.parse(fs.readFileSync(MEDITATIONS_PATH, "utf8"));

// Collect { text, filename } pairs — one per unique (sessionId, stepIndex) instruction
const entries = [];
const seen = new Set();

for (const session of meditations) {
  let stepIndex = 0;
  for (const step of session.steps) {
    if (step.instruction) {
      const filename = `${session.id}_step${stepIndex}`;
      if (!seen.has(step.instruction)) {
        seen.add(step.instruction);
        entries.push({ text: step.instruction, filename });
      }
    }
    stepIndex++;
  }
}

console.log(`Found ${entries.length} unique narration instructions.`);

// Load existing map (if any) so we can skip already-generated files
let narrationMap = {};
if (fs.existsSync(MAP_PATH)) {
  narrationMap = JSON.parse(fs.readFileSync(MAP_PATH, "utf8"));
}

async function generateNarration(text, filename) {
  const mp3Path = path.join(OUTPUT_DIR, `${filename}.mp3`);
  if (fs.existsSync(mp3Path)) {
    console.log(`  SKIP  ${filename}.mp3 (already exists)`);
    return;
  }

  const response = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`,
    {
      method: "POST",
      headers: {
        "xi-api-key": API_KEY,
        "Content-Type": "application/json",
        Accept: "audio/mpeg",
      },
      body: JSON.stringify({
        text,
        model_id: MODEL_ID,
        voice_settings: VOICE_SETTINGS,
      }),
    }
  );

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`ElevenLabs API error ${response.status}: ${body}`);
  }

  const buffer = await response.arrayBuffer();
  fs.writeFileSync(mp3Path, Buffer.from(buffer));
  console.log(`  DONE  ${filename}.mp3 (${(buffer.byteLength / 1024).toFixed(1)} KB)`);
}

let completed = 0;
let failed = 0;

for (const { text, filename } of entries) {
  try {
    await generateNarration(text, filename);
    narrationMap[text] = filename;
    completed++;
  } catch (err) {
    console.error(`  FAIL  ${filename}: ${err.message}`);
    failed++;
  }

  // Write map incrementally so progress is saved on interruption
  fs.writeFileSync(MAP_PATH, JSON.stringify(narrationMap, null, 2));
}

console.log(`\nDone. ${completed} generated, ${failed} failed.`);
console.log(`Narration map written to: ${MAP_PATH}`);
