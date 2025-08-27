// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ILayerZeroEndpoint {

    struct MessagingParams {
        uint32 dstEid;
        bytes32 receiver;
        bytes message;
    }

    struct MessagingReceipt {
       bytes32 guid;       // 全局唯一标识符
       uint64 nonce;       // 消息序号
    }

    event PacketSent(bytes encodedPayload, address sendLibrary);

    function send(MessagingParams calldata _params) external returns (MessagingReceipt memory receipt);
}