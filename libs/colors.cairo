from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_nn_le

struct Color:
    member red : felt
    member green : felt
    member blue : felt
end

struct PixelColor:
    # Adding "set" to avoid unset pixels to be considered black
    member set : felt
    member color : Color
end

func assert_valid_color_component{range_check_ptr}(color_component : felt):
    assert_nn_le(color_component, 255)
    return ()
end

func assert_valid_color{range_check_ptr}(color : Color):
    assert_valid_color_component(color.red)
    assert_valid_color_component(color.green)
    assert_valid_color_component(color.blue)
    return ()
end