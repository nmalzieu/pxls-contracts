from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_nn_le

struct Color {
    red: felt,
    green: felt,
    blue: felt,
}

struct PixelColor {
    // Adding "set" to avoid unset pixels to be considered black
    set: felt,
    color: Color,
}

func assert_valid_color_component{range_check_ptr}(color_component: felt) {
    assert_nn_le(color_component, 255);
    return ();
}

func assert_valid_color{range_check_ptr}(color: Color) {
    assert_valid_color_component(color.red);
    assert_valid_color_component(color.green);
    assert_valid_color_component(color.blue);
    return ();
}
