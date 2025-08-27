// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


library MessageLib {
    function encodeSend(bytes32 _sendTo, uint64 _amount) internal pure returns (bytes memory) {
        return abi.encodePacked(_sendTo, _amount);
    }
}