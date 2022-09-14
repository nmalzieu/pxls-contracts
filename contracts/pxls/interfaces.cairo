%lang starknet

from starkware.cairo.common.uint256 import Uint256
from pxls.utils.colors import Color, PixelColor
from pxls.PixelDrawer.colorization import Colorization

@contract_interface
namespace IPXLMetadata {
    func get_pixel_metadata(pixel_index: felt) -> (
        pixel_metadata_len: felt, pixel_metadata: felt*
    ) {
    }
}

@contract_interface
namespace IPixelERC721 {
    func initialize(pixel_drawer_address: felt) {
    }
    func matrixSize() -> (size: Uint256) {
    }
    func maxSupply() -> (count: Uint256) {
    }
    func totalSupply() -> (count: Uint256) {
    }
    func mint(to: felt) {
    }
    func pixelsOfOwner(owner: felt) -> (pixels_len: felt, pixels: felt*) {
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
namespace IPixelDrawer {
    func start() {
    }
    func pixelERC721Address() -> (address: felt) {
    }
    func colorizePixels(tokenId: Uint256, colorizations_len: felt, colorizations: Colorization*) {
    }
    func pixelColor(round: felt, pixelIndex: felt) -> (color: PixelColor) {
    }
    func currentDrawingPixelColor(pixelIndex: felt) -> (color: PixelColor) {
    }
    func currentDrawingTimestamp() -> (timestamp: felt) {
    }
    func drawingTimestamp(round: felt) -> (timestamp: felt) {
    }
    func currentDrawingRound() -> (round: felt) {
    }
    func launchNewRoundIfNecessary(theme_len: felt, theme: felt*) -> (launched: felt) {
    }
    func getGrid(round: felt) -> (grid_len: felt, grid: felt*) {
    }
    func owner() -> (owner: felt) {
    }
    func transferOwnership(newOwner: felt) -> () {
    }
    func everyoneCanLaunchRound() -> (bool: felt) {
    }
    func setEveryoneCanLaunchRound(bool: felt) {
    }
    func numberOfColorizations(round: felt, tokenId: Uint256) -> (count: felt) {
    }
    func totalNumberOfColorizations(round: felt) -> (count: felt) {
    }
    func maxColorizationsPerToken() -> (max: felt) {
    }
    func setMaxColorizationsPerToken(new_max: felt) {
    }
    func numberOfColorizers(round: felt) -> (count: felt) {
    }
    func drawingTheme(round: felt) -> (theme_len: felt, theme: felt*) {
    }
}
