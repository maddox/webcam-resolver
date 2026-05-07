# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Webcam Resolver is a Ruby Sinatra web service that resolves the true streaming URLs of publicly hosted webcams from providers that cycle their URLs. Used as a proxy for apps like Channels Custom Channels.

## Development Commands

```bash
# Run locally (port 4567)
bundle exec rackup --host 0.0.0.0 -p 4567

# Build Docker image
docker build -t webcam-resolver .

# Run via Docker (maps to port 8000)
docker run -it --name webcam-resolver -p 8000:4567 webcam-resolver
```

## Architecture

Single-file application (`webcam-resolver.rb`) with two endpoints:
- `GET /camera/:provider/:camera` - returns streaming URL as text
- `GET /stream/:provider/:camera` - redirects to streaming URL

### Adding a Provider

Add a new `when` clause in `get_camera_url()`. Each provider has different resolution logic:
- **surfchex**: Scrapes HTML page, extracts m3u8 URL via regex
- **ipcamlive**: Fetches JSON API, constructs stream URL from response

## Deployment

Docker image published to `ghcr.io/maddox/webcam-resolver` via GitHub Actions on push to main. Builds for both amd64 and arm64 platforms.
