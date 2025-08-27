// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ILayerZeroEndpoint} from "../interfaces/ILayerZeroEndpoint.sol";
import {PacketCodec} from "./PacketCodec.sol";
contract Endpoint is ILayerZeroEndpoint {
    uint32 public immutable eid;
    mapping(uint32 => mapping(address => uint64)) public nonces;
    constructor(uint32 _eid) {
        eid = _eid;
    }

    function send(MessagingParams calldata _params) external returns (MessagingReceipt memory receipt) {
        // 初始状态：nonces[eid][msg.sender] 不存在
        uint64 nonce = ++nonces[eid][msg.sender];
        // 执行过程：
        // 1. nonces[eid][msg.sender] 返回 0（默认值）
        // 2. ++0 = 1
        // 3. nonce = 1
        // 4. nonces[eid][msg.sender] = 1
        
        // 创建数据包
        PacketCodec.Packet memory packet = PacketCodec.Packet({
            nonce: nonce,
            srcEid: eid,
            sender: msg.sender,
            dstEid: _params.dstEid,
            receiver: _params.receiver,
            guid: "",
            message: _params.message
        });

        // 生成 GUID
        packet.guid = PacketCodec.generateGuid(packet);

        // 编码数据包
        bytes memory encodedPacket = PacketCodec.encode(packet);

        emit PacketSent(encodedPacket, address(this));

        receipt = MessagingReceipt({
            guid: packet.guid,
            nonce: packet.nonce
        });

        return receipt;
    }
}