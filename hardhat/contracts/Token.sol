// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./IERC20.sol";

contract Token is IERC20 {
    uint256 private supply;

    string public name;
    string public symbol;
    uint8 decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;

        supply = 1000;
    }

    function totalSupply() external view returns (uint256) {
        return supply;
    }

    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return balances[_account];
    }

    function transfer(address _to, uint256 _amount)
        external
        override
        returns (bool)
    {
        require(
            balances[msg.sender] >= _amount,
            "Not enough balance to transfer"
        );
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != _spender, "Cannot set allowance for oneself");
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount)
        external
        override
        returns (bool)
    {
        require(msg.sender != address(0), "Cannot approve Zero address");
        require(msg.sender != address(0), "Cannot approve Zero address");
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);

        return true;
    }

    function transferFrom(
        address _sender,
        address _to,
        uint256 _amount
    ) external override returns (bool) {
        require(
            allowances[_sender][msg.sender] >= _amount,
            "No approval to transfer mentioned amount"
        );

        allowances[_sender][msg.sender] -= _amount;
        balances[_sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(_sender, _to, _amount);
        return true;
    }
}
