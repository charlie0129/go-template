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

# Setup make
include makefiles/common.mk

# ===== Common Targets for subprojects (foo and bar) ======

SUBPROJS := $(patsubst %.mk, %, $(wildcard *.mk))

# Run `make TARGET' to run TARGET for both foo and bar.
#   For example, `make build' will build both foo and bar binaries.

# Common targets for subprojects, will be executed on all subprojects
TARGETS := build       \
    all-build          \
    package            \
    all-package        \
    container          \
    container-push     \
    all-container-push \
    clean              \
    all-clean          \
    version            \
    imageversion       \
    binaryname         \
    variables

# Default target, subprojects will be called with default target too
all: $(addprefix mk-all.,$(SUBPROJS));

# Default target for subprojects. make foo / make bar
$(foreach p,$(SUBPROJS),$(eval \
    $(p): mk-all.$(p);         \
))

# Run common targets on all subprojects
$(foreach t,$(TARGETS),$(eval                \
    $(t): $(addprefix mk-$(t).,$(SUBPROJS)); \
))

# `shell' only needs to be executed once, not on every subproject
shell: $(addprefix mk-shell.,$(word 1,$(SUBPROJS)));

# `help' is handled separately to show targets in this file.
help: # @HELP show general help message
help:
	echo "GENERAL_TARGETS:"
	grep -E '^.*: *# *@HELP' $(firstword $(MAKEFILE_LIST)) \
	    | sed -E 's_.*.mk:__g'                   \
	    | awk '                                  \
	        BEGIN {FS = ": *# *@HELP"};          \
	        { printf "  %-23s %s\n", $$1, $$2 }; \
	    '
	echo
	echo "Please run 'make all-help' to see the full help message for all subprojects."

all-help: # @HELP show help messages for all subjects
all-help: $(addprefix mk-help.,$(SUBPROJS))

# Run `make SUBPROJ-TARGET' to run TARGET for SUBPROJ.
#   For example, `make foo-build' will only build foo binary.

# Run `make help' to see all available targets for subprojects. Similarly,
# `make foo-help' will show help for foo.

# Targets to run on a specific subproject (<subproj>-<target>)
$(foreach p,$(SUBPROJS),$(eval \
    $(p)-%: mk-%.$(p);         \
))

mk-%:
	echo "# make -f $(lastword $(subst ., ,$*)).mk $(firstword $(subst ., ,$*))"
	$(MAKE) -f $(lastword $(subst ., ,$*)).mk $(firstword $(subst ., ,$*))

# ===== General Targets ======

lint: # @HELP lint code
lint:
	bash build/lint.sh ./...

boilerplate: # @HELP check file header
boilerplate:
	bash hack/verify-boilerplate.sh
