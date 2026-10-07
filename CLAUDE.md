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

# Tests (build the image first; there is no host ruby). The mount runs your
# working copy, so editing a test doesn't mean rebuilding the image.
docker run --rm -v "$PWD":/code webcam-resolver bundle exec ruby test/playlist_test.rb  # offline
docker run --rm -v "$PWD":/code webcam-resolver bundle exec ruby test/live_test.rb      # hits providers
```

## Tests

`test/playlist_test.rb` is offline and fast: it covers `best_variant` and
`rewrite_playlist`, the logic both playlist-serving providers share.

`test/live_test.rb` resolves a real cam from each provider. That's deliberate --
resolution is screen scraping plus undocumented endpoints, so the failure worth
catching is a provider changing something, which no mocked test would see. Every
provider is asserted all the way to "a segment actually fetches", including the
one that redirects, since a stale redirect target is exactly the sort of thing a
URL-shaped assertion waves through. `test_surfchex_serves_the_live_stream_and_not_the_promo_loop`
guards the silent failure described under "Surfchex: stream passes" below.

When a live test fails, check the cam in a browser first -- a cam that has simply
gone offline looks the same as provider drift. The cams are named in constants at
the top of the file; swap one out if it goes away for good.

## Architecture

Single-file application (`webcam-resolver.rb`) with two endpoints:
- `GET /camera/:provider/:camera` - returns streaming URL as text
- `GET /stream/:provider/:camera` - redirects to streaming URL (surfline and surfchex serve a rewritten playlist instead, see below)

### Adding a Provider

Add a new `when` clause in `get_camera_url()`. Each provider has different resolution logic:
- **surfchex**: `:camera` is the cam's page slug (`/cams/<slug>/`) or its hls cam id. Maps slug to cam id via the `CAM_PAGES` map in the page markup, then signs `https://www.surfchex.com/hls/<cam id>/index.m3u8` with a stream pass
- **ipcamlive**: Fetches JSON API, constructs stream URL from response
- **surfline**: `:camera` is the cam's hex id (the part after `/cam/` in an embed URL like `https://embed.cdn-surfline.com/cam/<id>.html`). Scrapes that embed page for the `hls.cdn-surfline.com` m3u8 URL.

If the resolved URL can't be handed to a client as-is, also add the provider to
`PLAYLIST_HEADERS` -- that table is what makes `/stream` serve the playlist itself
instead of redirecting, and it carries whatever headers the CDN wants.

### Surfchex: stream passes

Surfchex signs its playlists. An unsigned `/hls/<cam id>/index.m3u8` returns `200` with a
short promo loop instead of the live stream, which is silent -- no error to notice. The
site's player fetches `https://surfchex.com/api/stream-pass?cam=<cam id>` (`{"st","e"}`,
`404 {"error":"unknown cam"}` for an unknown cam, which is what makes `/camera` return a
real 404) and appends `?st=<token>&e=<expiry>` to the playlist URL. Passes last about ten
minutes, so they're cached in-process until shortly before expiry; slug -> cam id
mappings are cached once resolved. Segments are signed the same way, but the tokens come
baked into the playlist's segment names, so nothing extra is needed to fetch them.

### Surfline and surfchex: why `/stream` is special-cased

Neither provider's playlist URL can simply be handed to a client. Surfline gates both the embed `.html` page and the `.m3u8` playlist behind a `Referer` header (a bare request returns `403`), so resolution and playlist fetches both send `Referer: https://www.surfline.com/`. The `.ts` segments, however, are served publicly. A plain redirect would `403` because the client can't supply that header. So `/stream/surfline` does not redirect — it fetches the playlist with the `Referer` itself and rewrites the relative segment names to absolute CDN URLs, so the client streams segments straight from Surfline's CDN (no proxying/buffering/disk on the server). The playlist is a live sliding window with no `#EXT-X-ENDLIST`, so the player keeps re-requesting `/stream/surfline/:camera` and always gets the current segments. `/camera/surfline` returns the raw (referer-gated) playlist URL.

Surfchex needs the same treatment for a different reason: its stream pass expires, so a
redirect would hand the client a URL that dies mid-stream. Serving the playlist ourselves
means every refresh is re-signed with a current pass. `/camera/surfchex` returns a signed
URL, so it too is only good until that pass expires.

Both go through `resolve_playlist`, which follows a master playlist to its highest-bitrate
variant before rewriting, so segment and `#EXT-X-MAP` URIs always come back absolute.

## Deployment

Docker image published to `ghcr.io/maddox/webcam-resolver` via GitHub Actions on push to main. Builds for both amd64 and arm64 platforms.

### Workflows

`tests.yml` has no triggers of its own -- it is the one definition of "run the
suite", called from the other two. `docker-publish.yml` calls it as a `test` job
that `build` depends on, so a failing test blocks publishing (and runs on every
PR and every push to main). `tests-daily.yml` calls it on a daily cron, so
provider drift surfaces even when nobody touches the repo.

The schedule is deliberately in its own file. GitHub disables *scheduled*
workflows after 60 days of repository inactivity -- that is what silently stopped
publishing in August 2026 -- so if it happens again the daily drift check goes
quiet while the publish gate keeps working. A failing live test blocks publishing
by design; if a cam dies for good, swap the constant in `test/live_test.rb`.

When the daily run fails, it opens a `provider-drift` issue (or comments on the
one already open) and, for a new issue only, runs Claude via
`anthropics/claude-code-action` to diagnose it and open a PR, or comment its
findings if it can't fix it. `claude.yml` does the same on demand: the repo owner
mentions `@claude` in an issue or PR comment. Both authenticate with the
`CLAUDE_CODE_OAUTH_TOKEN` secret.
