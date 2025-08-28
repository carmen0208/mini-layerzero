// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ILayerZeroEndpoint} from "../interfaces/ILayerZeroEndpoint.sol";
import {PacketCodec} from "./PacketCodec.sol";
import {ILayerZeroReceiver} from "../interfaces/ILayerZeroReceiver.sol";

contract Endpoint is ILayerZeroEndpoint {
    uint32 public immutable eid;
    mapping(uint32 => mapping(address => uint64)) public nonces;
    mapping(bytes32 => bool) public verifiedPayloads;
    mapping(bytes32 => bool) public deliveredMessages;

    event PacketVerified(Origin indexed _origin, address indexed _receiver, bytes32 indexed _guid);
    event PacketDelivered(Origin origin, address receiver);

    /**
     * @dev Constructor for Endpoint
     * @param _eid The chain ID for this endpoint
     */
    constructor(uint32 _eid) {
        eid = _eid;
    }

    /**
     * @dev Sends a message to another chain via LayerZero
     * @param _params The messaging parameters containing destination chain, receiver, and message
     * @return receipt The receipt containing the generated GUID and nonce
     */
    function send(MessagingParams calldata _params) external returns (MessagingReceipt memory receipt) {
        // Initial state: nonces[eid][msg.sender] doesn't exist
        uint64 nonce = ++nonces[eid][msg.sender];
        // Execution process:
        // 1. nonces[eid][msg.sender] returns 0 (default value)
        // 2. ++0 = 1
        // 3. nonce = 1
        // 4. nonces[eid][msg.sender] = 1

        // Create packet
        PacketCodec.Packet memory packet = PacketCodec.Packet({
            nonce: nonce,
            srcEid: eid,
            sender: msg.sender,
            dstEid: _params.dstEid,
            receiver: _params.receiver,
            guid: "",
            message: _params.message
        });

        // Generate GUID
        packet.guid = PacketCodec.generateGuid(packet);

        // Encode packet
        bytes memory encodedPacket = PacketCodec.encode(packet);

        emit PacketSent(encodedPacket, address(this));

        receipt = MessagingReceipt({guid: packet.guid, nonce: packet.nonce});

        return receipt;
    }

    /**
     * @dev Receives and processes incoming LayerZero messages
     * @param _origin The origin information of the message
     * @param _receiver The address of the receiver contract
     * @param _guid The global unique identifier of the message
     * @param _message The message content
     */
    function lzReceive(Origin calldata _origin, address _receiver, bytes32 _guid, bytes calldata _message) external {
        // Check if message is verified (simplified version: directly mark as verified)
        if (!verifiedPayloads[_guid]) {
            verifiedPayloads[_guid] = true;
            emit PacketVerified(_origin, _receiver, keccak256(_message));
        }

        // Check if message is delivered
        require(!deliveredMessages[_guid], "Endpoint: message already delivered");
        deliveredMessages[_guid] = true;

        try ILayerZeroReceiver(_receiver).lzReceive(_origin, _guid, _message) {
            emit PacketDelivered(_origin, _receiver);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Endpoint: lzReceive failed - ", reason)));
        }
    }
}
