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
        uint256 amountSentLD;      // 实际发送数量
        uint256 amountReceivedLD; // 实际接收数量
    }
}