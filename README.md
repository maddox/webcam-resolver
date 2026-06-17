# Webcam Resolver!!

Webcam Resolver is a tool that will return the true streaming URLs of publicly hosted webcams hosted by providers that cycle their URLs.

Some providers cycle the streaming URLs of their webcams to prevent people from directly linking to their streams. This tool will resolve the true streaming URLs of these webcams.

Use this tool as a proxy to get the true streaming URL for a webcam to use in other streaming apps like with [Custom Channels](https://getchannels.com/custom-channels/) in the [Channels](https://getchannels.com) app.

## How to use

Webcam Resolver is a simple web service. It has two endpoints that accept two properties, `provider` and `camera_id`.

The provider is the name of the provider that hosts the webcam. The camera_id is the identifier of the webcam found in the public URL of the webpage hosting the camera.

## Providers Supported

- Surfchex
  - example URL: `http://www.surfchex.com/cams/avon/`
  - provider: `surfchex`
- IPCamLive

  - example URL: `https://www.ipcamlive.com/6495b042d1523`
  - provider: `ipcamlive`
- Surfline

  - example URL: `https://embed.cdn-surfline.com/cam/58349ab8e411dc743a5d52a0.html`
  - provider: `surfline`
  - The camera id is the hex id from the embed URL (the part after `/cam/`). Find it by inspecting the `<iframe>` of a page that embeds the cam, or via the embed/share code on surfline.com. Some pages inject the iframe with JavaScript, so check the live DOM rather than "View Source".

### A note on Surfline

Surfline gates the `.m3u8` playlist behind a `Referer` header (a bare request returns `403`), but serves the `.ts` video segments publicly. Because the client can't supply that header, `/stream/surfline` does not redirect like the other providers. Instead it fetches the playlist with the `Referer` itself and rewrites the relative segment names to absolute CDN URLs, so the client streams the video straight from Surfline's CDN — no proxying, buffering, or disk use on the server. `/camera/surfline` still returns the raw (referer-gated) playlist URL.

## Endpoints

Use these 2 endpoints to resolve the true streaming URLs of webcams.

### `GET` /camera/:provider/:camera_id

This will return the true streaming URL of the webcam as a string.

#### Examples

    /camera/surfchex/avon
    /camera/ipcamlive/6495b042d1523
    /camera/surfline/58349ab8e411dc743a5d52a0

### `GET` /stream/:provider/:camera_id

This will redirect the request to the true streaming URL of the webcam. Use this endpoint with other applications as the URL of your stream.

#### Examples

    /stream/surfchex/avon
    /stream/ipcamlive/6495b042d1523
    /stream/surfline/58349ab8e411dc743a5d52a0

## Installation

This project was designed to be hosted by Docker. You can run it manually, but it is not recommended.

### Docker

Run Webcam Resolver with Docker.

#### Command

    docker run -it --name webcam-resolver -p 8000:4567 ghcr.io/maddox/webcam-resolver

#### Docker Compose

```
webcam-resolver:
  image: ghcr.io/maddox/webcam-resolver
  container_name: webcam-resolver
  ports:
    - "8000:4567"
  restart: always
```

### Manually

Just start the service with the command below:

`ruby webcam_resolver.rb`
