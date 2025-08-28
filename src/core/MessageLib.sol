// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library MessageLib {
    error InvalidMessage();

    /**
     * @dev Encodes send parameters into a message
     * @param _sendTo The recipient address as bytes32
     * @param _amount The amount to send in shared decimals
     * @return The encoded message
     */
    function encodeSend(bytes32 _sendTo, uint64 _amount) internal pure returns (bytes memory) {
        return abi.encodePacked(_sendTo, _amount);
    }

    /**
     * @dev Extracts the recipient address from an encoded message
     * @param _message The encoded message
     * @return The recipient address as bytes32
     */
    function sendTo(bytes calldata _message) internal pure returns (bytes32) {
        if (_message.length < 32) revert InvalidMessage(); // 32
        return bytes32(_message[0:32]);
    }

    /**
     * @dev Decode shared decimal amount
     * @param _message Encoded message
     * @return amountShared Shared decimal amount
     */
    function amountShared(bytes calldata _message) internal pure returns (uint64) {
        if (_message.length < 40) revert InvalidMessage(); // 32 + 8
        return uint64(bytes8(_message[32:40]));
    }
}
