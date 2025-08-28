// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {PacketCodec} from "../../src/core/PacketCodec.sol";
import {AddressCast} from "../../src/core/AddressCast.sol";
import {Endpoint} from "../../src/core/Endpoint.sol";
import {ILayerZeroEndpoint} from "../../src/interfaces/ILayerZeroEndpoint.sol";
import {console} from "forge-std/console.sol";

contract TestHelper {
    using AddressCast for bytes32;
    using PacketCodec for bytes;

    mapping(uint32 => Endpoint) public endpoints; // eid => endpoint
    mapping(uint32 => mapping(address => PacketCodec.Packet[])) public messageQueue;
    mapping(bytes32 => bool) public processedMessages;

    /**
     * @dev Sets the endpoint for a specific chain ID
     * @param _eid The chain ID
     * @param _endpoint The endpoint contract address
     */
    function setEndpoint(uint32 _eid, address _endpoint) external {
        endpoints[_eid] = Endpoint(_endpoint);
    }

    /**
     * @dev Schedules a packet for delivery by adding it to the message queue
     * @param _packet The encoded packet to schedule
     */
    function schedulePacket(bytes memory _packet) external {
        PacketCodec.Packet memory packet = _packet.decode();
        address receiver = packet.receiver.bytes32ToAddress();

        console.log("receiver:", receiver);
        messageQueue[packet.dstEid][receiver].push(packet);
    }

    /**
     * @dev Delivers all scheduled messages for a specific receiver on a destination chain
     * @param _dstEid The destination chain ID
     * @param _receiver The receiver contract address
     */
    function deliverMessages(uint32 _dstEid, address _receiver) external {
        PacketCodec.Packet[] storage packets = messageQueue[_dstEid][_receiver];
        Endpoint dstEndpoint = endpoints[_dstEid];
        console.log("packet.length:", packets.length);

        for (uint256 i = 0; i < packets.length; i++) {
            PacketCodec.Packet memory packet = packets[i];
            console.log("packet.address:", packet.receiver.bytes32ToAddress());
            if (processedMessages[packet.guid]) {
                continue;
            }
            processedMessages[packet.guid] = true;
            // Build origin information
            ILayerZeroEndpoint.Origin memory origin = ILayerZeroEndpoint.Origin({
                srcEid: packet.srcEid,
                sender: AddressCast.addressToBytes32(packet.sender),
                nonce: packet.nonce
            });

            try dstEndpoint.lzReceive(origin, _receiver, packet.guid, packet.message) {}
            catch Error(string memory reason) {
                // Delivery failed, cancel mark
                processedMessages[packet.guid] = false;
                revert(string(abi.encodePacked("TestHelper: delivery failed - ", reason)));
            }
        }
    }
}
