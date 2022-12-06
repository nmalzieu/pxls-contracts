%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from pxls.RtwrkThemeAuction.storage import colorizers_balance

func fix_pxl_400_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Load the balance which was wrongfully assigned to PXL #0 (unexistent)
    let (pxl_0_balance: Uint256) = colorizers_balance.read(Uint256(0, 0));
    // Reset the balance for PXL #0
    colorizers_balance.write(Uint256(0, 0), Uint256(0, 0));
    // Write the balance for PXL #400
    colorizers_balance.write(Uint256(400, 0), pxl_0_balance);
    return ();
}
