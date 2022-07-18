%lang starknet

from starkware.cairo.common.uint256 import Uint256
from libs.colors import Color, PixelColor

@contract_interface
namespace IPXLMetadata:
    func get_pixel_metadata(pixel_index : felt) -> (
        pixel_metadata_len : felt, pixel_metadata : felt*
    ):
    end
end

@contract_interface
namespace IPixelERC721:
    func initialize(pixel_drawer_address : felt):
    end
    func matrixSize() -> (size : Uint256):
    end
    func maxSupply() -> (count : Uint256):
    end
    func totalSupply() -> (count : Uint256):
    end
    func mint(to : felt):
    end
    func pixelsOfOwner(owner : felt) -> (pixels_len : felt, pixels : felt*):
    end
    func transferFrom(from_ : felt, to : felt, tokenId : Uint256):
    end
    func setContractURIHash(index : felt, hash : felt):
    end
    func contractURI() -> (contractURI_len : felt, contractURI : felt*):
    end
    func tokenURI(tokenId : Uint256) -> (tokenURI_len : felt, tokenURI : felt*):
    end
    func owner() -> (owner : felt):
    end
end

@contract_interface
namespace IPixelDrawer:
    func start():
    end
    func pixelERC721Address() -> (address : felt):
    end
    func setPixelColor(tokenId : Uint256, color : Color):
    end
    func pixelColor(tokenId : Uint256) -> (color : PixelColor):
    end
    func currentDrawingTimestamp() -> (timestamp : felt):
    end
    func tokenPixelIndex(tokenId : Uint256) -> (pixelIndex : felt):
    end
    func currentDrawingRound() -> (round : felt):
    end
    func launchNewRoundIfNecessary() -> (launched : felt):
    end
    func pixelIndexToPixelColor(round : felt, pixelIndex : felt) -> (color : PixelColor):
    end
    func getGrid(round : felt) -> (grid_len : felt, grid : felt*):
    end
    func owner() -> (owner : felt):
    end
end
