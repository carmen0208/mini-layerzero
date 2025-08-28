// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {console} from "forge-std/console.sol";
import {PacketCodec} from "../../src/core/PacketCodec.sol";
import {AddressCast} from "../../src/core/AddressCast.sol";
import {TestHelper} from "./testHelper.sol";

contract EventHandler {
    using AddressCast for bytes32;
    using PacketCodec for bytes;

    mapping(bytes32 => bool) public processedEvents;


    event MessageScheduled(uint32 indexed dstEid, address indexed receiver, bytes32 indexed guid);


    TestHelper public immutable testHelper;

    /**
     * @dev Constructor for EventHandler
     * @param _testHelper The TestHelper contract address
     */
    constructor(address _testHelper) {
        testHelper = TestHelper(_testHelper);
    }

    /**
     * @dev Handles PacketSent events by decoding and scheduling them for delivery
     * @param _encodedPacket The encoded packet data from the event
     */
    function handlePacketSent(bytes memory _encodedPacket) external {
        PacketCodec.Packet memory packet = _encodedPacket.decode();

        // Check if already processed
        require(!processedEvents[packet.guid], "EventHandler: already processed");
        processedEvents[packet.guid] = true;

        console.log("--------------------------------");
        console.log("packet.guid:");
        console.logBytes32(packet.guid);
        console.log("packet.srcEid:", packet.srcEid);
        console.log("packet.dstEid:", packet.dstEid);
        console.log("packet.sender:", packet.sender);
        console.log("packet.receiver:", packet.receiver.bytes32ToAddress());
        console.log("packet.nonce:", packet.nonce);
        console.log("packet.message:");
        console.logBytes(packet.message);
        console.log("--------------------------------");

        // Add message to message queue
        testHelper.schedulePacket(_encodedPacket);

        emit MessageScheduled(packet.dstEid, packet.receiver.bytes32ToAddress(), packet.guid);
    }
}