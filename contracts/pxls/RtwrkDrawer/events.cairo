%lang starknet
from starkware.cairo.common.uint256 import Uint256
from pxls.RtwrkDrawer.colorization import PixelColorization

@event
func pixels_colorized(
    pxl_id: Uint256,
    account_address: felt,
    pixel_colorizations_len: felt,
    pixel_colorizations: PixelColorization*,
) {
}
