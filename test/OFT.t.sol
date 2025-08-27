// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {SimpleOFT} from "../src/oft/SimpleOFT.sol";
import {AddressCast} from "../src/core/AddressCast.sol";
import {IOFT} from "../src/interfaces/IOFT.sol";
import {Endpoint} from "../src/core/Endpoint.sol";

contract OFTTest is Test {
    using AddressCast for address;
    using AddressCast for bytes32;
    // 测试链配置
    uint32 public constant CHAIN_A = 1;
    uint32 public constant CHAIN_B = 2;


    Endpoint public endpointA;
    SimpleOFT public oftA;
    Endpoint public endpointB;
    SimpleOFT public oftB;

    address public userA;
    address public userB;
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10 ** 18; // 100万代币
    uint256 public constant USER_INITIAL_BALANCE = 100000 * 10 ** 18; // 10万代币

    function setUp() public {
        userA = makeAddr("userA");
        userB = makeAddr("userB");

        vm.deal(userA, 100 ether);
        vm.deal(userB, 100 ether);
        endpointA = new Endpoint(CHAIN_A);
        endpointB = new Endpoint(CHAIN_B);

        oftA = new SimpleOFT("OFTA", "OFTA", address(endpointA), INITIAL_SUPPLY);
        oftB = new SimpleOFT("OFTB", "OFTB", address(endpointB), INITIAL_SUPPLY);

        oftA.setPeer(CHAIN_B, address(oftB).addressToBytes32());
        oftB.setPeer(CHAIN_A, address(oftA).addressToBytes32());

        oftA.mint(userA, USER_INITIAL_BALANCE);
    }

    function test_OFT_Send() public {
        uint256 transferAmount = 5000 * 10 ** 18;
        uint256 minAmountLD = transferAmount * 99 / 100;

        uint256 userABalanceBefore = oftA.balanceOf(userA);

        vm.prank(userA);
        IOFT.SendParam memory params = IOFT.SendParam({
            dstEid: CHAIN_B,
            to: userB.addressToBytes32(),
            amountLD: transferAmount,
            minAmountLD: minAmountLD
        });

        IOFT.OFTReceipt memory oftReceipt = oftA.send(params);

        assertEq(
            oftReceipt.amountSentLD,
            transferAmount,
            "Amount sent should match"
        );

        uint256 userABalanceAfter = oftA.balanceOf(userA);
 
        console.log("userABalanceBefore:", userABalanceBefore);
        console.log("transferAmount:", transferAmount);
        console.log("userABalanceAfter :", userABalanceAfter);
        assertEq(
            userABalanceAfter, 
            userABalanceBefore - transferAmount, 
            "UserA balance should decrease"
        );

    }
}