// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC2771Context} from "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";
import {ERC2771Forwarder} from "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Forwarder.sol";
import "../lib/forge-std/src/console.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract Counter is ERC2771Forwarder, ERC2771Context {
    using ECDSA for bytes32;
    uint256 public number;

    constructor()
        ERC2771Forwarder("DummyProtocol")
        ERC2771Context(address(this))
    {}

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function hashTypedDataV4(bytes32 param) public view returns (bytes32) {
        return _hashTypedDataV4(param);
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
        // NOTE: I don't have to implement the nonce. It seems everything is handled by the `ERC2771Forwarder`

        // this verifies whether the user equals the signer.
        require(verify(metaTx), "WRONG#SIGNER");
        //require(_verify(_userAddress, metaTx, _signature), "NativeForwardRequest#executeForwardRequest: SIGNER_AND_SIGNATURE_DO_NOT_MATCH");

        //nonces[_userAddress]++;
        _useNonce(metaTx.from);

        // TODO: instead of below, use the `execute` function.
        execute(metaTx);
        //(bool success, bytes memory returnData) = address(this).call{value: msg.value}(abi.encodePacked(_functionData, _userAddress));
    }

    function generateMessage(
        address _from,
        address _to, // this contract
        uint256 _value, // 0
        uint _gas, //300000
        bytes memory _data // 0x3fb5c1cb0000000000000000000000000000000000000000000000000000000000000005 (setNumber(5))
    ) public view returns (bytes32, uint, uint) {
        uint deadline = block.timestamp + 1 days;

        return (
            keccak256(
                abi.encode(
                    _FORWARD_REQUEST_TYPEHASH,
                    _from,
                    _to,
                    _value,
                    _gas,
                    nonces(_from),
                    deadline,
                    _data
                )
            ),
            deadline,
            nonces(_from)
        );
    }
}
