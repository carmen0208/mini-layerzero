// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IOFT} from "../interfaces/IOFT.sol";
import {ILayerZeroEndpoint} from "../interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "../interfaces/ILayerZeroReceiver.sol";
import {MessageLib} from "../core/MessageLib.sol";
import {DecimalConverter} from "../core/DecimalConverter.sol";
import {AddressCast} from "../core/AddressCast.sol";

abstract contract OFTCore is IOFT, ILayerZeroReceiver {
    using MessageLib for bytes;
    using AddressCast for bytes32;

    ILayerZeroEndpoint public immutable endpoint;

    mapping(uint32 => bytes32) public peers;

    uint256 public immutable decimalConverterRate;
    uint8 public immutable sharedDecimals;

    error InvalidEndpoint();
    error InvalidPeer(uint32 eid);

    constructor(address _endpoint, uint8 _localDecimals) {
        if (_endpoint == address(0)) revert InvalidEndpoint();

        endpoint = ILayerZeroEndpoint(_endpoint);
        sharedDecimals = _sharedDecimals();
        // Calculate decimal conversion rate (18 - sharedDecimals)
        decimalConverterRate = 10 ** (_localDecimals - _sharedDecimals());
    }

    function _debit(
        address _from,
        uint256 _amountLD
    ) internal virtual returns (uint256 amountSentLD, uint256 amountReceivedLD);

    function _credit(
        address _to,
        uint256 _amountLD
    ) internal virtual returns (uint256 amountReceivedLD);

    function _sharedDecimals() public view virtual returns (uint8) {
        return 6;
    }


    function _buildMessage(SendParam calldata _sendParam) internal view returns (bytes memory) {
        return MessageLib.encodeSend(_sendParam.to, DecimalConverter.toSharedDecimal(_sendParam.amountLD, decimalConverterRate));
    }

    function _lzReceive(ILayerZeroEndpoint.Origin calldata _origin, bytes32 _guid, bytes calldata _message) internal {
        address toAddress = _message.sendTo().bytes32ToAddress();
        uint64 amountShared = _message.amountShared();
        uint256 amountLD = DecimalConverter.toLocalDecimal(amountShared, decimalConverterRate);

        uint256 amountReceivedLD = _credit(toAddress, amountLD);

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }

    function setPeer(uint32 _eid, bytes32 peer) external {
        peers[_eid] = peer;
    }

    function send(SendParam calldata _sendParam) external returns (OFTReceipt memory receipt) {
        bytes32 peer = peers[_sendParam.dstEid];
        if (peer == bytes32(0)) {
            revert InvalidPeer(_sendParam.dstEid);
        }

        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(msg.sender, _sendParam.amountLD);
        bytes memory message = _buildMessage(_sendParam);
        ILayerZeroEndpoint.MessagingParams memory params = ILayerZeroEndpoint.MessagingParams({
            dstEid: _sendParam.dstEid,
            receiver: peers[_sendParam.dstEid],
            message: message
        });

        endpoint.send(params);
        receipt = OFTReceipt({
            amountSentLD: amountSentLD,
            amountReceivedLD: amountReceivedLD
        });
    }

    function lzReceive(
        ILayerZeroEndpoint.Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message
    ) external {
        _lzReceive(_origin, _guid, _message);
    }
}