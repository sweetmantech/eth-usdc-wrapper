// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "@forge-std/src/Test.sol";
import {InProcessEthUsdcWrapper} from "../src/InProcessEthUsdcWrapper.sol";
import {IWETH9} from "../src/interfaces/IWETH9.sol";
import {ISwapRouter02} from "../src/interfaces/ISwapRouter02.sol";
import {IERC20Minter} from "../src/interfaces/IERC20Minter.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IQuoterV2} from "../src/interfaces/IQuoterV2.sol";
import {MockSwapFactory, MockQuoterV2, MockToken, MockSwapRouter, MockERC20Minter} from "./MockSwapFactory.sol";

contract InProcessEthUsdcWrapperTest is Test {
    InProcessEthUsdcWrapper public wrapper;
    MockSwapFactory public mockSwapFactory;
    MockQuoterV2 public quoterV2;
    MockToken public tokenIn;
    MockToken public tokenOut;
    MockSwapRouter public mockSwapRouter;
    MockERC20Minter public mockERC20Minter;

    address public DEFAULT_MINTER = address(0x01);
    uint256 public tokenId = 1;
    uint256 public quantity = 1;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;

    function setUp() public {
        wrapper = new InProcessEthUsdcWrapper();
        mockSwapFactory = new MockSwapFactory();
        quoterV2 = new MockQuoterV2();
        tokenIn = new MockToken();
        tokenOut = new MockToken();
        mockSwapRouter = new MockSwapRouter();
        mockERC20Minter = new MockERC20Minter();
    }

    function test_ReceiveEth() public {
        wrapper = new InProcessEthUsdcWrapper();
        payable(address(wrapper)).transfer(1 ether);
        assertEq(address(wrapper).balance, 1 ether);
    }

    function test_Mint() public {
        vm.deal(DEFAULT_MINTER, 1 ether);
        vm.startPrank(DEFAULT_MINTER);
        
        wrapper.mint{value: 1 ether}( 
            address(mockSwapFactory),
            address(mockSwapRouter),
            address(quoterV2),
            address(tokenIn),
            address(tokenOut),
            3000,
            1 ether,
            address(mockERC20Minter),
            address(0x0),
            tokenId,
            quantity,
            "comment!"
        );
    }
    
}