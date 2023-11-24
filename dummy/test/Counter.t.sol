// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ERC2771Forwarder} from "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Forwarder.sol";
import {ERC2771Context} from "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

struct ForwardRequest {
    address from;
    address to;
    uint256 value;
    uint256 gas;
    uint256 nonce;
    uint48 deadline;
    bytes data;
}

contract Counter is ERC2771Forwarder {
    using ECDSA for bytes32;
    uint256 public number;

    constructor() ERC2771Forwarder("DummyProtocol") {}

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function hashTypedDataV4(bytes32 param) public view returns (bytes32) {
        return _hashTypedDataV4(param);
    }

    function increment() public {
        number++;
    }

    function structHash(
        ForwardRequest calldata request
    ) external view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _FORWARD_REQUEST_TYPEHASH,
                        request.from,
                        request.to,
                        request.value,
                        request.gas,
                        request.nonce,
                        request.deadline,
                        keccak256(request.data)
                    )
                )
            );
    }
}

contract CounterTest is Test {
    using ECDSA for bytes32;
    Counter public counter;
    address from;
    /**
     * User variables
     */
    uint FROM_PRIV_KEY;
    bytes32 constant _FORWARD_REQUEST_TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint48 deadline,bytes data)"
        );

    function setUp() public {
        vm.deal(address(10), 10 ether);
        vm.startPrank(address(10));
        counter = new Counter();
        FROM_PRIV_KEY = vm.envUint("PRIV");
        from = vm.addr(FROM_PRIV_KEY);
        emit log_address(from);
        counter.setNumber(0);

        vm.deal(from, 10 ether);
        vm.startPrank(from);

        vm.stopPrank();
    }

    /**
     * There's a difference between the ForwardRequestData and ForwardRequestSignature
     * The `FRData` is the signed struct, whereas the FR is the plain struct to be signed.
     *
     */
    function _generateRequestData(
        uint nonce,
        uint48 deadline,
        bytes memory data
    ) private view returns (ERC2771Forwarder.ForwardRequestData memory) {
        // get the request
        ForwardRequest memory request = ForwardRequest({
            from: from,
            to: address(counter),
            value: 0,
            gas: 500000,
            nonce: nonce,
            deadline: deadline,
            data: data
        });

        // encode with V4 function
        bytes32 digest = counter.structHash(request);
        // sign it
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(FROM_PRIV_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        return
            ERC2771Forwarder.ForwardRequestData({
                from: request.from,
                to: request.to,
                value: request.value,
                gas: request.gas,
                deadline: request.deadline,
                data: request.data,
                signature: signature
            });
    }

    function test_final() public {
        vm.startPrank(address(this));

        ERC2771Forwarder.ForwardRequestData
            memory requestData = _generateRequestData(
                counter.nonces(from),
                uint48(block.timestamp + 10),
                abi.encodePacked(hex"3fb5c1cb", uint(5))
            );

        // verifies if signature matches `from`
        counter.verify(requestData);
    }
}
