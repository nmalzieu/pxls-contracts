from utils import run_cairo_function, str_to_single_felt

CAIRO_FILE_NAME = "libs/utils.cairo"


def test_coordinates_to_felt():
    return_values = run_cairo_function(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="coordinates_to_felt",
        inputs_dict={"x": 3, "y": 6},
        return_values=1,
    )
    assert return_values[0] == 195


def test_felt_to_coordinates():
    return_values = run_cairo_function(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="felt_to_coordinates",
        inputs_dict={"coordinate_felt": 195},
        builtins=["range_check"],
        return_values=2
    )
    assert return_values == [3, 6]


def test_axis_coordinate_shortstring():
    return_values = run_cairo_function(
        cairo_program_path=CAIRO_FILE_NAME,
        func_name="axis_coordinate_shortstring",
        inputs_dict={"c": 3},
        builtins=["range_check"],
        return_values=1
    )
    assert return_values == [str_to_single_felt("30")]