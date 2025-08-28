// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library AddressCast {
    /**
     * @dev Converts bytes32 to address by truncating to 160 bits
     * @param _addressBytes32 The bytes32 value to convert
     * @return addr The converted address
     */
    function bytes32ToAddress(bytes32 _addressBytes32) internal pure returns (address addr) {
        // Bytes32 -> uint256 == 256 bits -> 160 bits == 20 bytes -> address
        return address(uint160(uint256(_addressBytes32)));
    }

    /**
     * @dev Converts address to bytes32 by padding with zeros
     * @param _address The address to convert
     * @return addressBytes32 The converted bytes32 value
     */
    function addressToBytes32(address _address) internal pure returns (bytes32 addressBytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
