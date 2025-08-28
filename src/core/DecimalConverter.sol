// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library DecimalConverter {
    function toSharedDecimal(uint256 _amountLD, uint256 decimalConversionRate) internal pure returns (uint64) {
        // Calculate conversion rate: decimalConversionRate = 10 ^(local precision - shared precision)
        // Assuming local precision is 18, shared precision is 6 10 ** (18 - 6) = 10 ** 12
        // uint64 range: 0 to 18,446,744,073,709,551,615
        // For tokens with 6 decimal places, the maximum value is 18,446,744,073.709551615, enough for most use cases
        return uint64(_amountLD / decimalConversionRate);
    }

    function toLocalDecimal(uint64 _amountSD, uint256 decimalConversionRate) internal pure returns (uint256) {
        // Calculate conversion rate decimalConversionRate: 10^(local precision - shared precision)
        return uint256(_amountSD) * decimalConversionRate;
    }
}


