# Copyright 2022 Charlie Chiang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Those variables assigned with ?= can be overridden by setting them
# manually on the command line or using environment variables.

# Use build container or local go sdk. If use have go installed, then
# we use the local go sdk by default. Set USE_BUILD_CONTAINER to 1 manually
# to use build container.
USE_BUILD_CONTAINER ?=
ifeq (, $(shell which go))
  USE_BUILD_CONTAINER := 1
endif
# Go version used as the image of the build container, grabbed from go.mod
GO_VERSION       := $(shell grep -oE '^go [[:digit:]]{1,3}\.[[:digit:]]{1,3}' go.mod | sed 's/go //')
# Local Go release version (only supports go1.16 and later)
LOCAL_GO_VERSION := $(shell go env GOVERSION 2>/dev/null | grep -oE "go[[:digit:]]{1,3}\.[[:digit:]]{1,3}" || echo "none")
ifneq (1, $(USE_BUILD_CONTAINER)) # If not using build container, whcih means user have go installed. We need some checks.
  # Before go1.16, there is no GOVERSION. We don't support such case, so build container will be used.
  ifeq (none, $(LOCAL_GO_VERSION))
    $(warning You have $(shell go version | grep -oE " go[[:digit:]]{1,3}\.[[:digit:]]{1,3}.* " | xargs) locally, \
    which is not supported. Containerized build environment will be used instead.)
    USE_BUILD_CONTAINER := 1
  endif
  # Warn if local go release version is different from what is specified in go.mod.
  ifneq (none, $(LOCAL_GO_VERSION))
    ifneq (go$(GO_VERSION), $(LOCAL_GO_VERSION))
      $(warning Your local Go release ($(LOCAL_GO_VERSION)) is different from the one that this go module assumes (go$(GO_VERSION)).)
    endif
  endif
endif

# Copy binary instead of hard links when building (for bin/name-version/xxx <==> bin/name)
FORCE_COPY_BINARY ?= 0

# Build container image
BUILD_IMAGE ?= golang:$(GO_VERSION)

# The base image of container artifacts
BASE_IMAGE ?= gcr.io/distroless/static:nonroot

# Set DEBUG to 1 to optimize binary for debugging, otherwise for release
DEBUG ?=

# env to passthrough to the build container
GOFLAGS         ?=
GOPROXY         ?=
GOPRIVATE       ?=
HTTP_PROXY      ?=
HTTPS_PROXY     ?=
# GIT_CREDENTIALS format is the same as in ~/.git-credentials to help authenticate to private repositories
GIT_CREDENTIALS ?=

# Version string, use git tag by default
VERSION     ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "UNKNOWN")
GIT_COMMIT  ?= $(shell git rev-parse --verify HEAD 2>/dev/null || echo "UNKNOWN")

# Container image tag.
# If VERSION isn't a git tag, use latest.
# Otherwise, use VERSION and latest.
IMAGE_TAGS ?= $(shell bash -c ' \
  if [ ! $$(git tag -l "$(VERSION)") ]; then \
    echo latest;            \
  else                      \
    echo $(VERSION) latest; \
  fi')

# Full Docker image name (e.g. ghcr.io/charlie0129/foo:v1.0.0 docker.io/charlie0129/foo:v1.0.0  ghcr.io/charlie0129/foo:latest docker.io/charlie0129/foo:latest)
IMAGE_REPO_TAGS ?=
ifeq (, $(IMAGE_REPO_TAGS))
  $(foreach tag,$(IMAGE_TAGS),$(eval \
    IMAGE_REPO_TAGS += $(addsuffix /$(IMAGE_NAME):$(tag),$(IMAGE_REPOS)) \
  ))
endif

GOOS        ?=
GOARCH      ?=
# If user has not defined GOOS/GOARCH, use Go defaults.
# If user don't have Go, use the os/arch of their machine.
ifeq (, $(shell which go))
  HOSTOS     := $(shell uname -s | tr '[:upper:]' '[:lower:]')
  HOSTARCH   := $(shell uname -m)
  ifeq ($(HOSTARCH),x86_64)
    HOSTARCH := amd64
  endif
  ifeq ($(HOSTARCH),aarch64)
    HOSTARCH := arm64
  endif
  OS         := $(if $(GOOS),$(GOOS),$(HOSTOS))
  ARCH       := $(if $(GOARCH),$(GOARCH),$(HOSTARCH))
else
  OS         := $(if $(GOOS),$(GOOS),$(shell go env GOOS))
  ARCH       := $(if $(GOARCH),$(GOARCH),$(shell go env GOARCH))
endif

# Windows have .exe in the binary name
BIN_EXTENSION :=
ifeq ($(OS), windows)
    BIN_EXTENSION := .exe
endif

# Binary name
BIN_BASENAME      := $(BIN)$(BIN_EXTENSION)
# Binary name with extended info, i.e. version-os-arch
BIN_FULLNAME      := $(BIN)-$(VERSION)-$(OS)-$(ARCH)$(BIN_EXTENSION)
# Package filename (generated by `make package'). Use zip for Windows, tar.gz for all other platforms.
PKG_FULLNAME      := $(BIN_FULLNAME).tar.gz
# Checksum filename
CHECKSUM_FULLNAME := $(BIN)-$(VERSION)-checksums.txt
ifeq ($(OS), windows)
    PKG_FULLNAME  := $(subst .exe,,$(BIN_FULLNAME)).zip
endif

# This holds build output and helper tools
DIST           := bin
# This holds build cache, if build container is used
GOCACHE        := .go
# Full output directory
BIN_OUTPUT_DIR := $(DIST)/$(BIN)-$(VERSION)
PKG_OUTPUT_DIR := $(BIN_OUTPUT_DIR)/packages
# Full output path with filename
OUTPUT         := $(BIN_OUTPUT_DIR)/$(BIN_FULLNAME)
PKG_OUTPUT     := $(PKG_OUTPUT_DIR)/$(PKG_FULLNAME)
