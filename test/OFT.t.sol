// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, Vm} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SimpleOFT} from "../src/oft/SimpleOFT.sol";
import {AddressCast} from "../src/core/AddressCast.sol";
import {IOFT} from "../src/interfaces/IOFT.sol";
import {Endpoint} from "../src/core/Endpoint.sol";
import {PacketCodec} from "../src/core/PacketCodec.sol";
import {EventHandler} from "./helpers/EventHandler.sol";
import {TestHelper} from "./helpers/testHelper.sol";

contract OFTTest is Test {
    using AddressCast for address;
    using AddressCast for bytes32;
    using PacketCodec for bytes;
    // Test chain configuration

    uint32 public constant CHAIN_A = 1;
    uint32 public constant CHAIN_B = 2;

    Endpoint public endpointA;
    SimpleOFT public oftA;
    Endpoint public endpointB;
    SimpleOFT public oftB;
    EventHandler public eventHandler;
    TestHelper public testHelper;

    address public userA;
    address public userB;

    uint256 public constant INITIAL_SUPPLY = 1000000 * 10 ** 18; // 1 million tokens
    uint256 public constant USER_INITIAL_BALANCE = 100000 * 10 ** 18; // 100k tokens

    /**
     * @dev Sets up the test environment with two chains, endpoints, and OFT contracts
     */
    function setUp() public {
        testHelper = new TestHelper();
        eventHandler = new EventHandler(address(testHelper));

        userA = makeAddr("userA");
        userB = makeAddr("userB");

        vm.deal(userA, 100 ether);
        vm.deal(userB, 100 ether);
        endpointA = new Endpoint(CHAIN_A);
        endpointB = new Endpoint(CHAIN_B);

        testHelper.setEndpoint(CHAIN_A, address(endpointA));
        testHelper.setEndpoint(CHAIN_B, address(endpointB));

        oftA = new SimpleOFT("OFTA", "OFTA", address(endpointA), INITIAL_SUPPLY);
        oftB = new SimpleOFT("OFTB", "OFTB", address(endpointB), INITIAL_SUPPLY);

        oftA.setPeer(CHAIN_B, address(oftB).addressToBytes32());
        oftB.setPeer(CHAIN_A, address(oftA).addressToBytes32());

        oftA.mint(userA, USER_INITIAL_BALANCE);
    }

    /**
     * @dev Tests the complete cross-chain token transfer flow
     * Simulates sending tokens from Chain A to Chain B and processing the delivery
     */
    function test_SendAndDeliver() public {
        uint256 transferAmount = 5000 * 10 ** 18;
        uint256 minAmountLD = transferAmount * 99 / 100;

        uint256 userABalanceBefore = oftA.balanceOf(userA);
        uint256 userBBalanceBeforeB = oftB.balanceOf(userB);

        // Start recording events
        vm.recordLogs();

        vm.prank(userA);
        IOFT.SendParam memory params = IOFT.SendParam({
            dstEid: CHAIN_B,
            to: userB.addressToBytes32(),
            amountLD: transferAmount,
            minAmountLD: minAmountLD
        });

        console.log("userB:", userB);
        IOFT.OFTReceipt memory oftReceipt = oftA.send(params);
        assertEq(oftReceipt.amountSentLD, transferAmount, "Amount sent should match");

        // This test simulates off-chain work, processing PacketSent events and calling deliverMessage method.
        // Process PacketSent events, automatically dispatch messages
        _processPacketSentEvents(address(endpointA));
        // Process message queue
        testHelper.deliverMessages(CHAIN_B, address(oftB));

        uint256 userABalanceAfter = oftA.balanceOf(userA);
        uint256 userBBalanceAfterB = oftB.balanceOf(userB);

        console.log("userABalanceBefore:", userABalanceBefore);
        console.log("transferAmount:", transferAmount);
        console.log("userABalanceAfter :", userABalanceAfter);
        assertEq(userABalanceAfter, userABalanceBefore - transferAmount, "UserA balance should decrease");

        assertEq(userBBalanceAfterB, userBBalanceBeforeB + transferAmount, "UserB balance should increase on chain B");
    }

    /**
     * @dev Processes PacketSent events and forwards them to the event handler
     * @param _endpoint The endpoint address to filter events from
     */
    function _processPacketSentEvents(address _endpoint) internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == keccak256("PacketSent(bytes,address)") && log.emitter == address(_endpoint)) {
                // Parse event data
                (bytes memory encodedPacket, address sendLibrary) = abi.decode(logs[i].data, (bytes, address));

                eventHandler.handlePacketSent(encodedPacket);
            }
        }
    }
}
