BUILD:=build

THIS:=.
include project.mk


all: $(BUILD)/test.run

$(BUILD)/test.run: $(srcs) test.d
	mkdir -p $(dir $@)
	gdc -funittest -o "$@" $^

clean:
	rm -rf $(BUILD)
	mkdir $(BUILD)
