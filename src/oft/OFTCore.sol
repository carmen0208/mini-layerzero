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

    /**
     * @dev Constructor for OFTCore
     * @param _endpoint The LayerZero endpoint address
     * @param _localDecimals The local token decimals
     */
    constructor(address _endpoint, uint8 _localDecimals) {
        if (_endpoint == address(0)) revert InvalidEndpoint();

        endpoint = ILayerZeroEndpoint(_endpoint);
        sharedDecimals = _sharedDecimals();
        // Calculate decimal conversion rate (18 - sharedDecimals)
        decimalConverterRate = 10 ** (_localDecimals - _sharedDecimals());
    }

    /**
     * @dev Virtual function to handle token debiting (burning) when sending tokens
     * @param _from The address to debit tokens from
     * @param _amountLD The amount to debit in local decimals
     * @return amountSentLD The amount actually sent
     * @return amountReceivedLD The amount that will be received on destination chain
     */
    function _debit(address _from, uint256 _amountLD)
        internal
        virtual
        returns (uint256 amountSentLD, uint256 amountReceivedLD);

    /**
     * @dev Virtual function to handle token crediting (minting) when receiving tokens
     * @param _to The address to credit tokens to
     * @param _amountLD The amount to credit in local decimals
     * @return amountReceivedLD The amount actually received
     */
    function _credit(address _to, uint256 _amountLD) internal virtual returns (uint256 amountReceivedLD);

    /**
     * @dev Returns the shared decimals used across all chains
     * @return The number of shared decimals (default: 6)
     */
    function _sharedDecimals() public view virtual returns (uint8) {
        return 6;
    }

    /**
     * @dev Builds the cross-chain message for sending tokens
     * @param _sendParam The send parameters containing destination and amount
     * @return The encoded message for cross-chain transmission
     */
    function _buildMessage(SendParam calldata _sendParam) internal view returns (bytes memory) {
        return MessageLib.encodeSend(
            _sendParam.to, DecimalConverter.toSharedDecimal(_sendParam.amountLD, decimalConverterRate)
        );
    }

    /**
     * @dev Internal function to handle incoming LayerZero messages
     * @param _origin The origin information of the message
     * @param _guid The global unique identifier of the message
     * @param _message The encoded message containing recipient and amount
     */
    function _lzReceive(ILayerZeroEndpoint.Origin calldata _origin, bytes32 _guid, bytes calldata _message) internal {
        address toAddress = _message.sendTo().bytes32ToAddress();
        uint64 amountShared = _message.amountShared();
        uint256 amountLD = DecimalConverter.toLocalDecimal(amountShared, decimalConverterRate);

        uint256 amountReceivedLD = _credit(toAddress, amountLD);

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }

    /**
     * @dev Sets the peer contract address for a specific chain
     * @param _eid The chain ID to set the peer for
     * @param peer The peer contract address as bytes32
     */
    function setPeer(uint32 _eid, bytes32 peer) external {
        peers[_eid] = peer;
    }

    /**
     * @dev Sends tokens to another chain
     * @param _sendParam The send parameters containing destination chain, recipient, and amount
     * @return receipt The receipt containing the amounts sent and received
     */
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
        receipt = OFTReceipt({amountSentLD: amountSentLD, amountReceivedLD: amountReceivedLD});
    }

    /**
     * @dev Receives messages from LayerZero endpoint and processes them
     * @param _origin The origin information of the message
     * @param _guid The global unique identifier of the message
     * @param _message The encoded message containing recipient and amount
     */
    function lzReceive(ILayerZeroEndpoint.Origin calldata _origin, bytes32 _guid, bytes calldata _message) external {
        _lzReceive(_origin, _guid, _message);
    }
}
