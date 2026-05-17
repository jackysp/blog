.PHONY: all build check preview

all: build

build:
	go run main.go --gc --minify --cleanDestinationDir

check:
	go run ./tools/check-content

preview:
	go run main.go server -D --disableFastRender
