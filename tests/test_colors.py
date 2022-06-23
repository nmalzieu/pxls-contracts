from helpers.testing import run_cairo_function, assert_cairo_function_fails, get_cairo_structs

CAIRO_FILE_NAME = "libs/colors.cairo"
structs = get_cairo_structs(CAIRO_FILE_NAME)


def test_color_component():
    run_cairo_function(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="assert_valid_color_component",
        inputs_dict={"color_component": 0},
        builtins=["range_check"],
    )
    run_cairo_function(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="assert_valid_color_component",
        inputs_dict={"color_component": 255},
        builtins=["range_check"],
    )
    assert_cairo_function_fails(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="assert_valid_color_component",
        inputs_dict={"color_component": 260},
        builtins=["range_check"],
    )

def test_color():
    run_cairo_function(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="assert_valid_color",
        inputs_dict={"color": structs.Color(0, 0, 0)},
        builtins=["range_check"],
    )
    assert_cairo_function_fails(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="assert_valid_color",
        inputs_dict={"color": structs.Color(0, 0, 260)},
        builtins=["range_check"],
    )
