// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library DecimalConverter {
    function toSharedDecimal(uint256 _amountLD, uint256 decimalConversionRate) internal pure returns (uint64) {
        // 计算转换率：decimalConversionRate = 10 ^(本地精度 - 共享精度)
        // 假设本地精度是 18，共享精度是 6 10 ** (18 - 6) = 10 ** 12
        //  uint64 范围：0 到 18,446,744,073,709,551,615
        // 对于 6 位小数的代币，最大值为 18,446,744,073.709551615，足够大多数用例
        return uint64(_amountLD / decimalConversionRate);
    }

    function toLocalDecimal(uint64 _amountSD, uint256 decimalConversionRate) internal pure returns (uint256) {
        // 计算转换率decimalConversionRate ：10^(本地精度 - 共享精度)
        return uint256(_amountSD) * decimalConversionRate;
    }
}


