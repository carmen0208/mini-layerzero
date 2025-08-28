// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library PacketCodec {
    struct Packet {
        uint64 nonce; // Message sequence number
        uint32 srcEid; // Source chain ID
        address sender; // Sender address
        uint32 dstEid; // Destination chain ID
        bytes32 receiver; // Receiver address
        bytes32 guid; // Global unique identifier
        bytes message; // Message content
    }

    /**
     * @dev Generates a unique global identifier (GUID) for a packet
     * @param _packet The packet to generate GUID for
     * @return A unique 32-byte hash based on packet fields
     */
    function generateGuid(Packet memory _packet) internal pure returns (bytes32) {
        // abi.encodePacked result: directly concatenate values without adding type information
        // keccak256 - 32-byte unique hash value
        return
            keccak256(abi.encodePacked(_packet.nonce, _packet.srcEid, _packet.sender, _packet.dstEid, _packet.receiver));
    }

    /**
     * @dev Encodes a packet into a compact byte array using abi.encodePacked
     * @param _packet The packet to encode
     * @return The encoded packet as bytes
     */
    function encode(Packet memory _packet) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _packet.nonce,
            _packet.srcEid,
            _packet.sender,
            _packet.dstEid,
            _packet.receiver,
            _packet.guid,
            _packet.message
        );
    }

    /**
     * @dev Decodes encoded packet data back into a Packet struct
     * @param _encoded The encoded packet data
     * @return packet The decoded packet struct
     */
    function decode(bytes memory _encoded) internal pure returns (Packet memory packet) {
        uint256 offset = 0;
        // Parse nonce
        packet.nonce = uint64(bytes8(_slice(_encoded, offset, 8)));
        offset += 8;

        // Parse srcEid
        packet.srcEid = uint32(bytes4(_slice(_encoded, offset, 4)));
        offset += 4;

        // Parse sender
        packet.sender = address(bytes20(_slice(_encoded, offset, 20)));
        offset += 20;

        // Parse dstEid
        packet.dstEid = uint32(bytes4(_slice(_encoded, offset, 4)));
        offset += 4;

        // Parse receiver
        packet.receiver = bytes32(_slice(_encoded, offset, 32));
        offset += 32;

        // Parse guid
        packet.guid = bytes32(_slice(_encoded, offset, 32));
        offset += 32;

        // Parse message
        if (_encoded.length > offset) {
            packet.message = _slice(_encoded, offset, _encoded.length - offset);
        }
    }

    /**
     * @dev Extracts a slice of bytes from the input data
     * @param _data The input data to slice
     * @param _start The starting position for the slice
     * @param _length The length of the slice to extract
     * @return result The extracted byte slice
     */
    function _slice(bytes memory _data, uint256 _start, uint256 _length) private pure returns (bytes memory result) {
        require(_start + _length <= _data.length, "PacketCodec: slice out of bounds");
        result = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
            result[i] = _data[_start + i];
        }
    }
}
