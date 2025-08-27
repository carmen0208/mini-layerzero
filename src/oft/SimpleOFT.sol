// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OFT} from "./OFT.sol";

contract SimpleOFT is OFT {
    constructor(
        string memory name, 
        string memory symbol,
        address _endpoint,
        uint256 _initialSupply
    ) OFT(name, symbol, _endpoint, _initialSupply) {}

    /**
     * @dev local test only
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}