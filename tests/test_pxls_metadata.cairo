%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc

from contracts.pxls_metadata.pxls_metadata import append_palette_trait, get_pxl_json_metadata
from caistring.str import Str

@view
func test_append_palette_trait{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    let (trait : felt*) = alloc()
    # Palette 2 = magenta, 1 = "yes", with a comma at the end
    let (trait_len) = append_palette_trait(2, TRUE, FALSE, 0, trait)
    # Result must be {"trait_type":"magenta","value":"yes"}
    # in the form of 3 felts :
    # {"trait_type":"
    # magenta
    # ","value":"yes"},
    assert 3 = trait_len
    assert '{"trait_type":"' = trait[0]
    assert 'magenta' = trait[1]
    assert '","value":"yes"},' = trait[2]
    return ()
end

@view
func test_get_pixel_metadata{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (pixel_metadata_len : felt, pixel_metadata : felt*) = sample_pixel_metadata(0)

    # First pxl has 4 palettes : "cyan","yellow","magenta","blue" = 0,4,2,1
    assert 1 = pixel_metadata[0]
    assert 1 = pixel_metadata[1]
    assert 1 = pixel_metadata[2]
    assert 0 = pixel_metadata[3]
    assert 1 = pixel_metadata[4]
    assert 0 = pixel_metadata[5]

    # First pxl has 400 colors: pixel_metadata[6] => pixel_metadata[405]
    # Its 23rd color is #33FFFF . It is supposed to be stored at pixel_metadata[28]
    # and its value is supposed to be the color index of 33FFFF which is 3 in our list
    assert 3 = pixel_metadata[28]

    # Its last color is #FFCCFF . It is supposed to be stored at pixel_metadata[405]
    # and its value is supposed to be the color index of FFCCFF which is 10 in our list
    assert 10 = pixel_metadata[405]
    return ()
end

@view
func test_get_pxl_json_metadata{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    ):
    let (pixel_metadata_len : felt, pixel_metadata : felt*) = sample_pixel_metadata(0)
    let (pxl_json_metadata_len : felt, pxl_json_metadata : felt*) = get_pxl_json_metadata(
        grid_size=4, pixel_index=0, pixel_data_len=pixel_metadata_len, pixel_data=pixel_metadata
    )
    return ()
end

func sample_pixel_metadata{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pixel_index : felt
) -> (pixel_metadata_len : felt, pixel_metadata : felt*):
    let (pixels_location) = get_label_location(pixels_label)
    let pixels = cast(pixels_location, felt*)
    let pixel_metadata = pixels + 406 * pixel_index
    return (pixel_metadata_len=406, pixel_metadata=pixel_metadata)

    # All pxl metadata has been generated in advance
    # Each pxl consists of a list of palettes that compose
    # the pxl and a list of 400 colors that compose the 20x20
    # pxl grid. The pixels array is a list of felt.
    # Each pxl grid consists of a list of 406 felts :
    # pixel[i] where 0 <= i < 6 are 0 or 1, depending on if the palette
    # with index i composes this pixel. The 400 other felts
    # are the colors indexes of each 400 pixels in RGB

    # This is a method with just the first pxl, to some testing,
    # as big contracts break protostar

    pixels_label:
    dw 1
    dw 1
    dw 1
    dw 0
    dw 1
    dw 0
    dw 7
    dw 14
    dw 11
    dw 9
    dw 22
    dw 8
    dw 24
    dw 8
    dw 13
    dw 8
    dw 13
    dw 1
    dw 5
    dw 22
    dw 10
    dw 0
    dw 14
    dw 14
    dw 8
    dw 24
    dw 22
    dw 4
    dw 3
    dw 5
    dw 7
    dw 0
    dw 11
    dw 22
    dw 20
    dw 12
    dw 13
    dw 24
    dw 21
    dw 24
    dw 4
    dw 12
    dw 22
    dw 1
    dw 14
    dw 4
    dw 0
    dw 3
    dw 8
    dw 2
    dw 5
    dw 2
    dw 2
    dw 9
    dw 21
    dw 7
    dw 13
    dw 8
    dw 11
    dw 12
    dw 23
    dw 14
    dw 0
    dw 2
    dw 4
    dw 6
    dw 4
    dw 9
    dw 1
    dw 7
    dw 24
    dw 22
    dw 5
    dw 12
    dw 1
    dw 4
    dw 22
    dw 8
    dw 22
    dw 5
    dw 10
    dw 8
    dw 2
    dw 7
    dw 4
    dw 6
    dw 13
    dw 9
    dw 22
    dw 11
    dw 9
    dw 20
    dw 0
    dw 24
    dw 5
    dw 8
    dw 9
    dw 13
    dw 8
    dw 8
    dw 11
    dw 0
    dw 20
    dw 6
    dw 7
    dw 14
    dw 11
    dw 9
    dw 10
    dw 22
    dw 22
    dw 2
    dw 5
    dw 2
    dw 3
    dw 9
    dw 4
    dw 1
    dw 21
    dw 14
    dw 6
    dw 13
    dw 5
    dw 7
    dw 13
    dw 22
    dw 13
    dw 5
    dw 0
    dw 7
    dw 4
    dw 3
    dw 24
    dw 12
    dw 1
    dw 13
    dw 8
    dw 6
    dw 11
    dw 5
    dw 22
    dw 8
    dw 10
    dw 24
    dw 22
    dw 0
    dw 14
    dw 4
    dw 4
    dw 12
    dw 2
    dw 2
    dw 20
    dw 7
    dw 7
    dw 3
    dw 9
    dw 3
    dw 0
    dw 13
    dw 3
    dw 6
    dw 11
    dw 3
    dw 20
    dw 11
    dw 14
    dw 3
    dw 4
    dw 7
    dw 4
    dw 12
    dw 21
    dw 11
    dw 14
    dw 20
    dw 23
    dw 5
    dw 14
    dw 11
    dw 8
    dw 0
    dw 4
    dw 24
    dw 14
    dw 9
    dw 7
    dw 5
    dw 0
    dw 3
    dw 22
    dw 10
    dw 8
    dw 24
    dw 5
    dw 24
    dw 24
    dw 5
    dw 10
    dw 0
    dw 22
    dw 2
    dw 0
    dw 0
    dw 1
    dw 20
    dw 2
    dw 6
    dw 23
    dw 4
    dw 23
    dw 4
    dw 9
    dw 24
    dw 22
    dw 8
    dw 14
    dw 7
    dw 4
    dw 24
    dw 6
    dw 13
    dw 22
    dw 13
    dw 7
    dw 14
    dw 20
    dw 0
    dw 10
    dw 1
    dw 8
    dw 9
    dw 21
    dw 4
    dw 6
    dw 5
    dw 4
    dw 0
    dw 5
    dw 23
    dw 9
    dw 24
    dw 0
    dw 12
    dw 10
    dw 12
    dw 6
    dw 22
    dw 13
    dw 11
    dw 2
    dw 12
    dw 3
    dw 24
    dw 21
    dw 7
    dw 2
    dw 21
    dw 21
    dw 2
    dw 23
    dw 7
    dw 0
    dw 6
    dw 5
    dw 13
    dw 6
    dw 21
    dw 2
    dw 9
    dw 11
    dw 2
    dw 9
    dw 8
    dw 24
    dw 0
    dw 11
    dw 13
    dw 13
    dw 24
    dw 12
    dw 10
    dw 8
    dw 5
    dw 24
    dw 9
    dw 6
    dw 4
    dw 6
    dw 1
    dw 4
    dw 23
    dw 14
    dw 21
    dw 8
    dw 8
    dw 3
    dw 2
    dw 2
    dw 22
    dw 3
    dw 10
    dw 23
    dw 9
    dw 1
    dw 11
    dw 10
    dw 6
    dw 6
    dw 0
    dw 5
    dw 4
    dw 10
    dw 4
    dw 14
    dw 13
    dw 4
    dw 3
    dw 7
    dw 10
    dw 2
    dw 12
    dw 20
    dw 22
    dw 14
    dw 12
    dw 11
    dw 6
    dw 1
    dw 1
    dw 13
    dw 7
    dw 11
    dw 8
    dw 1
    dw 7
    dw 22
    dw 9
    dw 2
    dw 5
    dw 24
    dw 10
    dw 7
    dw 22
    dw 2
    dw 11
    dw 3
    dw 20
    dw 24
    dw 12
    dw 13
    dw 13
    dw 10
    dw 10
    dw 10
    dw 10
    dw 3
    dw 14
    dw 1
    dw 24
    dw 24
    dw 4
    dw 4
    dw 22
    dw 6
    dw 10
    dw 2
    dw 20
    dw 24
    dw 2
    dw 10
    dw 3
    dw 0
    dw 22
    dw 11
    dw 10
    dw 20
    dw 23
    dw 23
    dw 8
    dw 10
    dw 5
    dw 14
    dw 1
    dw 12
    dw 13
    dw 11
    dw 10
    dw 13
    dw 6
    dw 11
    dw 10
    dw 21
    dw 10
    dw 1
    dw 11
    dw 24
    dw 8
    dw 11
    dw 23
    dw 1
    dw 20
    dw 3
    dw 12
    dw 14
    dw 10
end
