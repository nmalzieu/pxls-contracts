%lang starknet

from starkware.cairo.common.uint256 import Uint256
from libs.colors import Color, PixelColor

@contract_interface
namespace IPixelERC721:
    func pixelDrawerAddress() -> (address : felt):
    end
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
end
