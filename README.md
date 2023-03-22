# template-go

This is a skeleton project for a Go application, which captures the best build techniques I have learned to date. It is inspired by [thockin/go-build-template](https://github.com/thockin/go-build-template), but heavily modified to suit my needs even better.

This has only been tested on Linux and macOS. Windows support is very unlikely to come.

## Features

- **Flexible build environments:** you can use a containerized build environment, so you can keep the build environment the same or still build when you don't have Go installed; or you can use your local Go SDK (by default, requires at least go1.16) for local developments;
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

By default, if you have Go in your PATH, it will use you local Go SDK. If you don't have Go, it will use a containerized build environment, specifically, a `golang:1.xx-alpine` Docker image. The actual `1.xx` go version will be determined by your `go.mod`. To manually specify the image of the containerized build environment, set `BUILD_IMAGE` to the Docker image you want, e.g. `golang:1.20`.

To make sure the build environment is the same across your teammates and avoid problems, it is recommended to use the containerized build environment. To forcibly use the containerized build environment, set `USE_BUILD_CONTAINER` to `1`. For example, `USE_BUILD_CONTAINER=1 make all-build`.

#### Debug build

Set `DEBUG` to `1` to build binary for debugging (disable optimizations and inlining), otherwise it will build for release (trim paths, disable symbols and DWARF).

#### Environment variables

These environment variables will be passed to the containerized build environment: `GOFLAGS`, `GOPROXY`, `HTTP_PROXY`, `HTTPS_PROXY`.

Setting `GOOS` and `GOARCH` will do cross-compiling, even when using the containerized build environment, just like you would expect.

#### Container base image

To build your container (I'm referring to the container artifact of your application, not the build container), you will need a base image. By default, this will be `gcr.io/distroless/static:nonroot`.

To customize it, set `BASE_IMAGE` to your desired image. For example, `BASE_IMAGE=scratch make container`.

#### Versioning

By default, `pkg/version.Version` will be determined by `git describe --tags --always --dirty`. For example, if you are on a git commit tagged as `v0.0.1`, then `pkg/version.Version` will be `v0.0.1`. The tag of your container will be `v0.0.1` as well. If you are not on that exact tagged commit, then the version will be something like `v0.0.1-1-b5f5feb`. The tag of your container will be `latest`.

To set the version manually, set `VERSION` to something you want. This will affect `pkg/version.Version`. Set `IMAGE_TAG` to the Docker image tag you want too.

#### Binary names

After building, two binaries will be generated. For example, one is `bin/foo`, another one is `bin/foo-v0.0.1/foo-v0.0.1-linux-amd64`. The long one is the compiler output. The short one is provided so you can use it more easily, and is hard-linked to the long one.

#### Makefile debugging

To show debug messages for makefile, set `DBG_MAKEFILE` to `1`.

## FAQ

- *Why don't you use multi-stage Dockerfile?* Because I want to utilize build cache to the most possible extent.
- *Why is my IDE indexing the build cache (.go)?* The build cache will only exist if you used the containerized build environment. If your IDE doesn't ignore it automatically, you can exclude it from indexing manually. For example, in GoLand, you can right-click on the `.go` directory to find relevant options.
- *Why does the Dockerfile have a .in extension?* Because `Dockerfile.in` is only a template. You can't actually run it. The actual usable Dockerfile will be generated by make. Refer to the comments in `Dockerfile.in` for details.