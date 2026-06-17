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
- **surfline**: `:camera` is the cam's hex id (the part after `/cam/` in an embed URL like `https://embed.cdn-surfline.com/cam/<id>.html`). Scrapes that embed page for the `hls.cdn-surfline.com` m3u8 URL.

### Surfline: why `/stream` is special-cased

Surfline gates the `.m3u8` playlist behind a `Referer` header (a bare request returns `403`), but serves the `.ts` segments publicly. A plain redirect would `403` because the client can't supply that header. So `/stream/surfline` does not redirect — it fetches the playlist with the `Referer` itself and rewrites the relative segment names to absolute CDN URLs, so the client streams segments straight from Surfline's CDN (no proxying/buffering/disk on the server). The playlist is a live sliding window with no `#EXT-X-ENDLIST`, so the player keeps re-requesting `/stream/surfline/:camera` and always gets the current segments. `/camera/surfline` returns the raw (referer-gated) playlist URL. If Surfline ever serves a master playlist with bitrate variants, the variant sub-playlists would need the same rewrite treatment.

## Deployment

Docker image published to `ghcr.io/maddox/webcam-resolver` via GitHub Actions on push to main. Builds for both amd64 and arm64 platforms.
