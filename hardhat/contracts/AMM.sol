// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "hardhat/console.sol";

// Constant Sum AMM -> X + Y = k
contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 reserve0;
    uint256 reserve1;

    uint256 totalSupply;
    mapping(address => uint256) balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _mint(address _to, uint256 _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        require(
            totalSupply >= _amount,
            "Amount to burn more than total supply of tokens"
        );
        require(_from != address(0), "From address is the zero address");
        require(
            balanceOf[_from] >= _amount,
            "Balance of from address not enough"
        );

        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
    }

    function _update(uint256 _amount0, uint256 _amount1) private {
        reserve0 = _amount0;
        reserve1 = _amount1;
    }

    function swap(address _tokenIn, uint256 _amount)
        external
        returns (uint256)
    {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "Token In address is invalid"
        );
        bool isToken0 = _tokenIn == address(token0);

        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isToken0
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);

        // Transfer tokenIn
        tokenIn.transferFrom(msg.sender, address(this), _amount);

        // Calculate tokenOut needed based on X + Y = k -> 0.3% commission of tokenOut
        uint256 amountIn = tokenIn.balanceOf(address(this)) - reserveIn; // Why can't we use the "_amount" here directly?
        uint256 amountOut = (amountIn * 997) / 1000;

        // Update reserves
        (uint256 res0, uint256 res1) = isToken0
            ? (reserveIn + amountIn, reserveOut - amountOut)
            : (reserveOut - amountOut, reserveIn + amountIn);

        _update(res0, res1);

        // Transfer tokenOut
        tokenOut.transfer(msg.sender, amountOut);

        return amountOut;
    }

    function addLiquidity(uint256 _amount0, uint256 _amount1)
        external
        returns (uint256 shares)
    {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        uint256 d0 = balance0 - reserve0;
        uint256 d1 = balance1 - reserve1;

        // s = a * T / L
        /*
          a = amount in
          L = total liquidity
          s = shares to mint
          T = total supply
        */
        if (totalSupply > 0) {
            shares = ((d0 + d1) * totalSupply) / (reserve0 + reserve1);
        } else {
            shares = d0 + d1;
        }

        require(shares > 0, "Shares is 0");
        _mint(msg.sender, shares);

        _update(balance0, balance1);
    }

    function removeLiquidity(uint256 _shares)
        external
        returns (uint256 d0, uint256 d1)
    {
        /*
          a = amount in
          L = total liquidity
          s = shares to mint
          T = total supply
        */
        // a = s * L / T
        d0 = (_shares * reserve0) / totalSupply;
        d1 = (_shares * reserve1) / totalSupply;

        _burn(address(this), _shares);
        _update(reserve0 - d0, reserve1 - d1);

        if (d0 > 0) {
            token0.transfer(msg.sender, d0);
        }
        if (d1 > 0) {
            token1.transfer(msg.sender, d1);
        }
    }
}
