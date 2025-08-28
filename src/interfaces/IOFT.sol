// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IOFT {
    struct SendParam {
        uint32 dstEid;
        bytes32 to;
        uint256 amountLD;
        uint256 minAmountLD;
    }

    struct OFTReceipt {
        uint256 amountSentLD;      // Actual amount sent
        uint256 amountReceivedLD; // Actual amount received
    }

    event OFTReceived(
        bytes32 indexed guid,
        uint32 srcEid,
        address indexed toAddress,
        uint256 amountReceivedLD
    );
}