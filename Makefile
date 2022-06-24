# Build and test
build :; rm -rf build/ && protostar build
test  :; protostar test tests/

.PHONY: build test
