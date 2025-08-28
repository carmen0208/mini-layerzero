// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./ILayerZeroEndpoint.sol";

/**
 * @title ILayerZeroReceiver
 * @dev LayerZero message receiver interface
 */
interface ILayerZeroReceiver {
    /**
     * @dev Callback function to receive LayerZero messages
     * @param _origin Message origin information
     * @param _guid Global unique identifier of the message
     * @param _message Message content
     */
    function lzReceive(
        ILayerZeroEndpoint.Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message
    ) external;

}
