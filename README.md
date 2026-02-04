# pdfnotes (v1.6.0)

A Flutter application for generating and managing PDF notes with AI-powered content generation and Text-to-Speech (TTS) capabilities.

## Features
- **AI PDF Generation**: Generate structured educational notes on any topic using Gemini AI.
- **Interactive Chat**: Chat with AI to refine topics and generate content.
- **Text-to-Speech (TTS)**: Listen to generated notes and chat messages using high-quality local TTS.
- **PDF Viewer**: Built-in viewer for generated and imported PDF documents.
- **Cross-Platform**: Supports Android, iOS, Windows, macOS, and Linux.

## Latest Changes (v1.6.0)
- Refactored TTS service for better local performance.
- Removed external `http` dependency in favor of native `HttpClient` for PDF downloads.
- Improved chat interface with interactive message bubbles.
- Added release management for APKs.

## Getting Started
1. Set your Gemini API key in the app settings (⚡ icon).
2. Type `#genpdf <topic>` to generate a new document.
3. Tap on an AI message to listen to it via TTS.

