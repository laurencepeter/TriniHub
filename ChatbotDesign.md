# Chatbot Design

## Overview
The chatbot is intended to provide guided help for dog registration, QR scanning, and troubleshooting. It supports online mode (LLM API) and offline mode (local JSON knowledge base).

## Architecture
- **UI Layer**: Chat screen with message list and input composer.
- **Service Layer**:
  - `ChatbotService` decides between API mode and offline mode based on environment variables.
  - `KnowledgeBase` loads canned responses from JSON when no API key is configured.
- **Safety Layer**:
  - Refuse sensitive requests (personal data, legal advice).
  - Display a disclaimer when entering chat.

## Configuration
- `CHATBOT_API_URL` (optional)
- `CHATBOT_API_KEY` (optional)
- When both are present, the app uses API mode.
- When missing, the app uses offline mode and loads responses from `assets/knowledge_base.json`.

## Offline Mode Behavior
- Matches user intent to a curated set of FAQ answers.
- Returns fallbacks such as “Here are steps to register a dog” or “Contact support.”

## Logging
- Log errors and moderation blocks to console in debug mode only.
- Never store user messages or personal data on device in release mode.
