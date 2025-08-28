// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OFTCore} from "./OFTCore.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OFT is OFTCore, ERC20 {
    /**
     * @dev Constructor for OFT token
     * @param name The token name
     * @param symbol The token symbol
     * @param _endpoint The LayerZero endpoint address
     * @param _initialSupply The initial token supply
     */
    constructor(string memory name, string memory symbol, address _endpoint, uint256 _initialSupply)
        ERC20(name, symbol)
        OFTCore(_endpoint, decimals())
    {
        if (_initialSupply > 0) {
            _mint(msg.sender, _initialSupply);
        }
    }

    /**
     * @dev Overrides the virtual _debit function to implement token burning
     * @param _from The address to debit tokens from
     * @param _amountLD The amount to debit in local decimals
     * @return amountSentLD The amount actually sent (1:1 conversion)
     * @return amountReceivedLD The amount that will be received on destination chain
     */
    function _debit(address _from, uint256 _amountLD)
        internal
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        // Simplified version: no fees, 1:1 conversion
        amountSentLD = _amountLD;
        amountReceivedLD = _amountLD;
        _burn(_from, _amountLD);
    }

    /**
     * @dev Overrides the virtual _credit function to implement token minting
     * @param _to The address to credit tokens to
     * @param _amountLD The amount to credit in local decimals
     * @return amountReceivedLD The amount actually received (1:1 conversion)
     */
    function _credit(address _to, uint256 _amountLD) internal override returns (uint256 amountReceivedLD) {
        // Simplified version: direct minting
        amountReceivedLD = _amountLD;
        _mint(_to, amountReceivedLD);
    }
}
