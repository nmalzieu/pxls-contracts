import os
from typing import Dict, List
from starkware.cairo.lang.compiler.cairo_compile import compile_cairo_files
from starkware.cairo.lang.cairo_constants import DEFAULT_PRIME
from starkware.cairo.common.cairo_function_runner import CairoFunctionRunner
from starkware.cairo.lang.vm.vm_exceptions import VmException
from starkware.cairo.common.structs import CairoStructFactory


def get_program(cairo_program_path):
    CAIRO_FILE = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(__file__))), cairo_program_path
    )
    COMPILED_CAIRO_FILE = compile_cairo_files([CAIRO_FILE], prime=DEFAULT_PRIME)
    return COMPILED_CAIRO_FILE

def get_cairo_structs(cairo_program_path):
    program = get_program(cairo_program_path)
    struct_factory = CairoStructFactory.from_program(program=program)
    return struct_factory.structs


def run_cairo_function(
    cairo_program_path,
    func_name: str,
    inputs_dict: Dict[str, int] = {},
    return_values=0,
    builtins: List[str] = [],
    layout="all",
):
    program = get_program(cairo_program_path)
    runner = CairoFunctionRunner(program=program, layout=layout)
    builtins_dict = {
        (builtin + "_ptr"): getattr(runner, builtin + "_builtin").base
        for builtin in builtins
    }
    runner.run(func_name, **inputs_dict, **builtins_dict)
    return runner.get_return_values(return_values)

def assert_cairo_function_fails(*args, **kwargs):
    try:
        return_values = run_cairo_function(*args, **kwargs)
        assert False, f"Cairo function did not fail, return values : {return_values}"
    except VmException as err:
        pass