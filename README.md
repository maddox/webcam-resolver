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

## Endpoints

Use these 2 endpoints to resolve the true streaming URLs of webcams.

### `GET` /camera/:provider/:camera_id

This will return the true streaming URL of the webcam as a string.

#### Examples

    /camera/surfchex/avon
    /camera/ipcamlive/6495b042d1523

### `GET` /stream/:provider/:camera_id

This will redirect the request to the true streaming URL of the webcam. Use this endpoint with other applications as the URL of your stream.

#### Examples

    /stream/surfchex/avon
    /stream/ipcamlive/6495b042d1523

## Installation

This project was designed to be hosted by Docker. You can run it manually, but it is not recommended.

### Docker

Run Webcam Resolver with Docker.

#### Command

    docker run -it --name webcam-resolver -p 8000:4567 jonmaddox/webcam-resolver

#### Docker Compose

```
webcam-resolver:
  image: webcam-resolver
  container_name: webcam-resolver
  ports:
    - "8000:4567"
  restart: always
```

### Manually

Just start the service with the command below:

`ruby webcam_resolver.rb`
