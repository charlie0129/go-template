# go-template

This is a skeleton project for a Go application, which captures the best build techniques I have learned to date. It is inspired by [thockin/go-build-template](https://github.com/thockin/go-build-template) , but heavily modified to suit my needs even better.

This has only been tested on Linux and macOS. Windows support is very unlikely to come.

## Features

- **Flexible build environments:** local Go SDK or Go build container; you can still build without Go SDK;
- **Efficient build cache:** when using the build container, build cache is volume-mounted to working directory to store incremental state for the fastest possible build;
- **Easy cross-compiling:** build binaries and container images for multiple OS/arch in one command;
- **Optimized artifacts:** best practices applied to optimize your binary / container image for either release or debug;
- **Fast distribution:** with one command, your binaries are built, for all platforms, packaged with licenses and checksums, ready for distribution.

## Dependencies

Chances are all the dependencies are already met on a dev machine.

- `GNU Make`: apparently
- `git`: to set binary version according to git tag
- `docker`: to build containers for your app, or if you want to use the containerized build environment
- `go`: only if you want use your local Go SDK
- `tar/zip`: packaging binaries
- `sha256sum`: calculating checksum

## Usage

```
  build                    (default) build binary for current platform
  all-build                build binaries for all platforms
  package                  build and package binary for current platform
  all-package              build and package binaries for all platforms
  container                build container image for current platform
  container-push           push built container image to all repos
  all-container-push       build and push container images for all platforms
```

> You can run `make help` to see all possible targets.

This template supports multiple apps, called subprojects, which is `foo` and `bar`, corresponding to `foo.mk` and `bar.mk`. In this example, `foo` and `bar` are just two hello-world binaries.

The main Makefile will automatically calls these subproject makefiles (`foo.mk` and `bar.mk`). So `make build` will build all subprojects (`foo` and `bar`). To run a target against a certain subproject, use `make <subproj>-<target>`. For example, `make foo-build` will only build `foo`.

Every target/subproject can be called in this way. For example, `make help` will show help for `foo` and `bar`, equivalent to calling `make foo-help` and `make bar-help`. But you may ask, the help message for the two are same, why do you show the same help twice? Because you can add custom make-targets to `foo.mk` or `bar.mk`. By which time they will show different help messages.

To add a new subproject, all you need to do is duplicate `foo.mk`, change it to `foobar.mk`, make proper changes, add some Go files, and that's it. You don't need to change anything else. Please take a look at `foo.mk` . Every variable is well-commented so it should be fairly straightforward understand.

## Advanced

#### Build environment

By default, if you have Go in your PATH, it will use you local Go SDK. If you don't have Go, it will use a containerized build environment, specifically, a `golang:1.xx-alpine` Docker image. The actual `1.xx` version will be determined by your `go.mod`. To force using the containerized build environment, set `USE_BUILD_CONTAINER` to `1`. For example, `USE_BUILD_CONTAINER=1 make all-build`

#### Debug build

Set `DEBUG` to `1` to build binary for debugging (disable optimizations and inlining), otherwise it will build for release (trim paths, disable symbols and DWARF).

#### Container base image

To build your container (I'm referring to the container artifact of your application, not the build container), you will need a base image. By default, this will be `gcr.io/distroless/static:nonroot`. To customize it, set `BASE_IMAGE` to your desired image. For example, `BASE_IMAGE=scratch make container`

#### Environment variables

These environment variables will be passed to the containerized build environment: `GOFLAGS`, `GOPROXY`, `HTTP_PROXY`, `HTTPS_PROXY`.

Setting `GOOS` and `GOARCH` will do cross-compiling, even when the containerized build environment, just like you would expect.

#### Binary names

By default, building for current platform will result in a simple binary name, e.g., `bin/foo` `bin/bar`. While building for all platforms will result in a full binary name, e.g., `bin/bar-v0.0.1/bar-v0.0.1-darwin-amd64`. To forcibly use full binary name, set `FULL_NAME` to `1`.

#### Makefile debugging

To show debug messages for makefile, set `DBG_MAKEFILE` to `1`.

## FAQ

- *Why don't you use multi-stage Dockerfile?* Because I wan't utilize build cache to the most possible extent.
- *Why is my IDE indexing the build cache (.go)?* The build cache will only exist if you used the containerized build environment. If your IDE doesn't ignore it automatically, you can exclude it from indexing manually. For example, in GoLand, you can right-click on the `.go` directory to find relevant options.