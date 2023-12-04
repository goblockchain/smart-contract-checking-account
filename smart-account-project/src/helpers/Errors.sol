//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

library Errors {
    error ForbiddenSender();
    error InvalidCalldata();
    error InvalidUser(address user);
    error ArrayLengthMismatch();
    error Locked();
    error Paused();
    error InvalidToken(address token);
    error UnableToMove();
    error InvalidSmartAccount(address smartAccount);
    error AmountIsZero();
    error AddressIsZero();
    error ReceivedNative();
}
