PACKAGE_NAME := $(shell cat info.json|jq -r .name)
VERSION_STRING := $(shell cat info.json|jq -r .version)

OUTPUT_NAME := $(PACKAGE_NAME)_$(VERSION_STRING)
OUTPUT_DIR := build/$(OUTPUT_NAME)

PKG_COPY := $(wildcard *.md) graphics locale sounds

SED_FILES := $(shell find . -iname '*.json' -type f -not -path "./build/*") $(shell find . -iname '*.lua' -type f -not -path "./build/*")
PNG_FILES := $(shell find ./graphics -iname '*.png' -type f)
OUT_FILES := $(SED_FILES:%=$(OUTPUT_DIR)/%)

SED_EXPRS := -e 's/{{MOD_NAME}}/$(PACKAGE_NAME)/g'
SED_EXPRS += -e 's/{{VERSION}}/$(VERSION_STRING)/g'

all: clean

release: clean package

package-copy: $(PKG_DIRS) $(PKG_FILES)
	mkdir -p $(OUTPUT_DIR)
ifneq ($(PKG_COPY),)
	cp -r $(PKG_COPY) build/$(OUTPUT_NAME)
endif

$(OUTPUT_DIR)/%.lua: %.lua
	@mkdir -p $(@D)
	@sed $(SED_EXPRS) $< > $@
	luac -p $@

$(OUTPUT_DIR)/%: %
	mkdir -p $(@D)
	sed $(SED_EXPRS) $< > $@

tag:
	git tag -f v$(VERSION_STRING)

optimize:
	for name in $(PNG_FILES); do \
		optipng -o8 $(OUTPUT_DIR)'/'$$name; \
	done

nodebug:
	sed -i 's/^\(.*DEBUG.*=\).*/\1 false/' ./$(OUTPUT_DIR)/config.lua
	sed -i 's/^\(.*LOGLEVEL.*=\).*/\1 0/' ./$(OUTPUT_DIR)/config.lua

check:
	luacheck.bat .

package: package-copy $(OUT_FILES) nodebug
	cd build && zip -r $(OUTPUT_NAME).zip $(OUTPUT_NAME)

clean:
	rm -rf build/