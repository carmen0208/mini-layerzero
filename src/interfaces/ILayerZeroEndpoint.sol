// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ILayerZeroEndpoint {
    struct Origin {
        uint32 srcEid;      // Source chain ID
        bytes32 sender;     // Sender address
        uint64 nonce;       // Message sequence number
    }

    struct MessagingParams {
        uint32 dstEid;
        bytes32 receiver;
        bytes message;
    }

    struct MessagingReceipt {
       bytes32 guid;       // Global unique identifier
       uint64 nonce;       // Message sequence number
    }

    event PacketSent(bytes encodedPayload, address sendLibrary);

    function send(MessagingParams calldata _params) external returns (MessagingReceipt memory receipt);

    function lzReceive(Origin calldata _origin, address _receiver, bytes32 _guid, bytes calldata _message) external;
}