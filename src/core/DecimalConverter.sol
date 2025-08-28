// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library DecimalConverter {
    /**
     * @dev Converts local decimal amount to shared decimal amount
     * @param _amountLD The amount in local decimals (e.g., 18 decimals)
     * @param _decimalConversionRate The conversion rate (10^(local - shared))
     * @return The amount converted to shared decimals (e.g., 6 decimals)
     */
    function toSharedDecimal(uint256 _amountLD, uint256 _decimalConversionRate) internal pure returns (uint64) {
        // Calculate conversion rate: _decimalConversionRate = 10 ^(local precision - shared precision)
        // Assuming local precision is 18, shared precision is 6 10 ** (18 - 6) = 10 ** 12
        // uint64 range: 0 to 18,446,744,073,709,551,615
        // For tokens with 6 decimal places, the maximum value is 18,446,744,073.709551615, enough for most use cases
        return uint64(_amountLD / _decimalConversionRate);
    }

    /**
     * @dev Converts shared decimal amount back to local decimal amount
     * @param _amountSD The amount in shared decimals (e.g., 6 decimals)
     * @param _decimalConversionRate The conversion rate (10^(local - shared))
     * @return The amount converted to local decimals (e.g., 18 decimals)
     */
    function toLocalDecimal(uint64 _amountSD, uint256 _decimalConversionRate) internal pure returns (uint256) {
        // Calculate conversion rate _decimalConversionRate: 10^(local precision - shared precision)
        return uint256(_amountSD) * _decimalConversionRate;
    }
}
