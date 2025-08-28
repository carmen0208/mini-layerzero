// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OFTCore} from "./OFTCore.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OFT is OFTCore, ERC20 {
    constructor(
        string memory name, 
        string memory symbol,
        address _endpoint,
        uint256 _initialSupply
    ) ERC20(name, symbol) OFTCore(_endpoint, decimals()) {
        if (_initialSupply > 0) {
            _mint(msg.sender, _initialSupply);
        }
    }

    function _debit(address _from, uint256 _amountLD) internal override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        // Simplified version: no fees, 1:1 conversion
        amountSentLD = _amountLD;
        amountReceivedLD = _amountLD;
        _burn(_from, _amountLD);
    }

    function _credit(address _to, uint256 _amountLD) internal override returns (uint256 amountReceivedLD) {
        // Simplified version: direct minting
        amountReceivedLD = _amountLD;
        _mint(_to, amountReceivedLD);
    }
}