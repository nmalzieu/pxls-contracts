%lang starknet

from starkware.cairo.common.uint256 import Uint256
from pxls.utils.colors import Color, PixelColor
from pxls.RtwrkDrawer.colorization import PixelColorization

@contract_interface
namespace IPxlMetadata {
    func get_pxl_metadata(pxl_id: felt) -> (pxl_metadata_len: felt, pxl_metadata: felt*) {
    }
}

@contract_interface
namespace IPxlERC721 {
    func matrixSize() -> (size: Uint256) {
    }
    func maxSupply() -> (count: Uint256) {
    }
    func totalSupply() -> (count: Uint256) {
    }
    func mint(to: felt) {
    }
    func pxlsOwned(owner: felt) -> (pxls_len: felt, pxls: felt*) {
    }
    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }
    func setContractURIHash(hash_len: felt, hash: felt*) {
    }
    func contractURI() -> (contractURI_len: felt, contractURI: felt*) {
    }
    func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }
    func owner() -> (owner: felt) {
    }
    func transferOwnership(newOwner: felt) -> () {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace IRtwrkDrawer {
    func pxlERC721Address() -> (address: felt) {
    }
    func colorizePixels(
        pxlId: Uint256, pixel_colorizations_len: felt, pixel_colorizations: PixelColorization*
    ) {
    }
    func currentRtwrkTimestamp() -> (timestamp: felt) {
    }
    func rtwrkTimestamp(rtwrkId: felt) -> (timestamp: felt) {
    }
    func currentRtwrkId() -> (rtwrk_id: felt) {
    }
    func launchNewRtwrkIfNecessary(theme_len: felt, theme: felt*) -> (launched: felt) {
    }
    func rtwrkGrid(rtwrkId: felt, rtwrkStep: felt) -> (grid_len: felt, grid: felt*) {
    }
    func owner() -> (owner: felt) {
    }
    func transferOwnership(newOwner: felt) -> () {
    }
    func numberOfPixelColorizations(rtwrkId: felt, pxlId: Uint256) -> (count: felt) {
    }
    func totalNumberOfPixelColorizations(rtwrkId: felt) -> (count: felt) {
    }
    func maxPixelColorizationsPerColorizer() -> (max: felt) {
    }
    func numberOfColorizers(rtwrkId: felt, rtwrkStep: felt) -> (count: felt) {
    }
    func colorizers(rtwrkId: felt, rtwrkStep: felt) -> (colorizers_len: felt, colorizers: felt*) {
    }
    func rtwrkTheme(rtwrkId: felt) -> (theme_len: felt, theme: felt*) {
    }
    func rtwrkStepsCount(rtwrkId: felt) -> (steps_count: felt) {
    }
}

@contract_interface
namespace IRtwrkERC721 {
    func totalSupply() -> (count: Uint256) {
    }
    func mint(to: felt) {
    }
    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }
    func setContractURIHash(hash_len: felt, hash: felt*) {
    }
    func contractURI() -> (contractURI_len: felt, contractURI: felt*) {
    }
    func exists(tokenId: Uint256) -> (token_exists: felt) {
    }
    func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }
    func owner() -> (owner: felt) {
    }
    func transferOwnership(newOwner: felt) -> () {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace IEthERC20 {
    func transfer(recipient: felt, amount: Uint256) {
    }
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) {
    }
}
