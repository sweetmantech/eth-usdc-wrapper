// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IWETH9} from "./interfaces/IWETH9.sol";
import {ISwapRouter02} from "./interfaces/ISwapRouter02.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC20Minter} from "./interfaces/IERC20Minter.sol";
import {IQuoterV2} from "./interfaces/IQuoterV2.sol";
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";

/// @title InProcessEthUsdcWrapper
contract InProcessEthUsdcWrapper {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    /// @notice Mints using ETH by swapping through Uniswap
    /// @param swapFactory The address of the Uniswap V3 factory
    /// @param swapRouter The address of the Uniswap V3 router
    /// @param quoterV2 The address of the Quoter V2 contract
    /// @param tokenIn The address of the input token (ETH)
    /// @param tokenOut The address of the output token (ERC20)
    /// @param fee The fee tier for the Uniswap pool
    /// @param amountOut The amount of output tokens to receive
    /// @param erc20MinterAddress The address of the ERC20 minter contract
    /// @param tokenContract The address of the token contract
    /// @param tokenId The ID of the token to mint
    /// @param quantity The quantity of tokens to mint
    /// @param comment A comment or note for the minting process
    function mint(
        address swapFactory,
        address swapRouter,
        address quoterV2,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        address erc20MinterAddress,
        address tokenContract,
        uint256 tokenId,
        uint256 quantity,
        string memory comment
    ) public payable {
        address pool = IUniswapV3Factory(swapFactory).getPool(tokenIn, tokenOut, fee);
        uint160 liquidity = IUniswapV3Pool(pool).liquidity();

        IQuoterV2.QuoteExactOutputSingleParams memory quoteExactOutputParams = IQuoterV2.QuoteExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amount: amountOut,
            fee: fee,
            sqrtPriceLimitX96: liquidity
        });
        uint256 amountIn;
        uint160 sqrtPriceX96After;
        uint32 initializedTicksCrossed;
        uint256 gasEstimate;
        
        (amountIn, sqrtPriceX96After, initializedTicksCrossed, gasEstimate) 
            = IQuoterV2(quoterV2).quoteExactOutputSingle(quoteExactOutputParams);

        require(msg.value >= amountIn, "Insufficient ETH");
        IWETH9(tokenIn).approve(swapRouter, amountIn);
        ISwapRouter02.ExactOutputSingleParams memory params = ISwapRouter02.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: address(this),
            amountOut: amountOut,
            amountInMaximum: amountIn,
            sqrtPriceLimitX96: liquidity
        });
        ISwapRouter02(swapRouter).exactOutputSingle{value: amountIn}(params);
        IERC20(tokenOut).approve(erc20MinterAddress, amountOut);
        IERC20Minter(erc20MinterAddress).mint(msg.sender, quantity, tokenContract, tokenId, amountOut, tokenOut, msg.sender, comment);
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}

    function withdraw(uint256 amount) external onlyOwner() {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(address(msg.sender)).transfer(amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
}