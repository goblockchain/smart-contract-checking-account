// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC2771Context} from "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";
import {ERC2771Forwarder} from "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Forwarder.sol";

contract Counter is ERC2771Forwarder, ERC2771Context{
    uint256 public number;

    constructor() ERC2771Forwarder("DummyProtocol") ERC2771Context(address(this)) {

    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function executeForwardRequest(
        // address _userAddress,
        // address _to,
        // uint _gas,
        // uint _value,
        // bytes calldata _functionData,
        // bytes calldata _signature,
        ForwardRequestData calldata metaTx
    ) external payable {
        //ForwardRequestData { address from; address to; uint256 value; uint256 gas; uint48 deadline; bytes data; bytes signature;}
        // ForwardRequestData memory metaTx = ForwardRequestData({from: _userAddress, to: _to, value: _value, gas: _gas, deadline: block.timestamp + 1 days, data: _functionData, signature: _signature});
        
        // this verifies whether the user equals the signer. 
        require(verify(metaTx), "WRONG#SIGNER");
        //require(_verify(_userAddress, metaTx, _signature), "NativeForwardRequest#executeForwardRequest: SIGNER_AND_SIGNATURE_DO_NOT_MATCH");

        //nonces[_userAddress]++;
        _useNonce(metaTx.from);

        // TODO: instead of below, use the `execute` function.
        execute(metaTx);
        //(bool success, bytes memory returnData) = address(this).call{value: msg.value}(abi.encodePacked(_functionData, _userAddress));

        /*
        // Bubble up error based on https://ethereum.stackexchange.com/a/83577
        if (!success) {
            assembly {
                // Slice the sighash.
                returnData := add(returnData, 0x04)
            }

            revert(abi.decode(returnData, (string)));
        }
        return returnData;
        */
        
    }

    /*
    function _verify(
        address _signer,
        ForwardRequestData memory _metaTx,
        bytes calldata _signature
    ) private view returns (bool) {
        bytes32 structHash = keccak256(abi.encode(META_TRANSACTION_TYPEHASH, _metaTx.nonce, _metaTx.from, keccak256(_metaTx.functionData)));
        bytes32 typedDataHash = _hashTypedDataV4(structHash);

        return _signer == ECDSAUpgradeable.recover(typedDataHash, _signature);
    }
    */

}
