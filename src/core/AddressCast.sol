// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library AddressCast {
    function bytes32ToAddress(bytes32 _addressBytes32) internal pure returns (address addr) {
        // Bytes32 -> uint256 == 256 bits -> 160 bits == 20 bytes -> address
        return address(uint160(uint256(_addressBytes32)));
    }

    function addressToBytes32(address _address) internal pure returns (bytes32 addressBytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}