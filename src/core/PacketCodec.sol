// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library PacketCodec {
    struct Packet {
        uint64 nonce;       // 消息序号
        uint32 srcEid;      // 源链 ID
        address sender;     // 发送者地址
        uint32 dstEid;      // 目标链 ID
        bytes32 receiver;   // 接收者地址
        bytes32 guid;       // 全局唯一标识符
        bytes message;      // 消息内容
    }

    function generateGuid(Packet memory _packet) internal pure returns (bytes32) {
        // abi.encodePacked 结果：将值直接连接，不添加类型信息
        // keccak256 - 32 字节的唯一哈希值
        return keccak256(abi.encodePacked(
            _packet.nonce,
            _packet.srcEid,
            _packet.sender,
            _packet.dstEid,
            _packet.receiver
        ));
    }

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

    function decode(bytes memory _data) internal pure returns (Packet memory) {
        return abi.decode(_data, (Packet));
    }
}