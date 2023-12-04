// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/*╔═════════════════════════════╗
      ║        CHECK FUNCTIONS      ║
      ╚═════════════════════════════╝*/

import {Errors} from "./helpers/Errors.sol";

contract Checks {
    function ifZeroRevert(uint amount) internal pure {
        if (amount == 0) revert Errors.AmountIsZero();
    }

    function revertIfZeroAddress(address token) internal pure {
        if (token == address(0)) revert Errors.AddressIsZero();
    }
}
