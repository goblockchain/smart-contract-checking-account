// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter, ERC2771Forwarder} from "../src/Counter.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

// import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract CounterTest is Test {
    using ECDSA for bytes32;
    Counter public counter;
    address from;
    uint8 v;
    bytes32 r;
    bytes32 s;
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

    function test_final() public {
        vm.startPrank(address(this));

        // Prepare the message hash using the same hashing method
        bytes32 messageHash = keccak256(
            abi.encode(
                _FORWARD_REQUEST_TYPEHASH,
                from,
                address(counter),
                0,
                500000,
                uint48(block.timestamp + 86400),
                keccak256(abi.encodePacked(hex"3fb5c1cb", abi.encode(uint(5))))
            )
        );

        (uint8 v_, bytes32 r_, bytes32 s_) = vm.sign(
            FROM_PRIV_KEY,
            messageHash
        );
        bytes memory _signature1 = abi.encodePacked(r_, s_, v_);

        //----------------------------------------------------------------------
        /*
         * ```solidity
         * bytes32 digest = _hashTypedDataV4(
         * keccak256(
         * abi.encode(
         * keccak256(
         * "Mail(address to,string contents)"
         * ), // keccak256
         *     mailTo,
         *     keccak256(bytes(mailContents))
         * ) // encode
         * ) // keccak
         * ); // hashTypedDataV4
         * address signer = ECDSA.recover(digest, signature);
         * ```
         */
        // NOTE: trying to follow above's example:
        bytes memory _data = abi.encodePacked(
            keccak256(abi.encodePacked(hex"3fb5c1cb", abi.encode(uint(5))))
        );

        bytes32 digest = counter.hashTypedDataV4(
            keccak256(
                abi.encode(
                    _FORWARD_REQUEST_TYPEHASH,
                    from,
                    address(counter),
                    0,
                    500000,
                    uint48(block.timestamp + 86400),
                    _data,
                    _signature1
                )
            )
        );

        (uint8 vv, bytes32 rr, bytes32 ss) = vm.sign(FROM_PRIV_KEY, digest);

        bytes memory _signature2 = abi.encodePacked(rr, ss, vv);
        emit log_named_bytes("sig", _signature2);

        counter.verify(
            ERC2771Forwarder.ForwardRequestData({
                from: from,
                to: address(counter),
                value: 0, // Set your desired value
                gas: 500000, // You can set your desired gas value
                deadline: uint48(block.timestamp + 86400), // Set your desired deadline
                data: _data,
                signature: _signature2
            })
        );

        // works
        (address recovered, , ) = ECDSA.tryRecover(messageHash, _signature1);
        emit log_address(recovered);
    }
}

/**
 *          bytes32 digest = _hashTypedDataV4(keccak256(
                abi.encode(
                    _FORWARD_REQUEST_TYPEHASH,
                    request.from,
                    request.to,
                    request.value,
                    request.gas,
                    nonces(request.from),
                    request.deadline,
                    keccak256(request.data)
                )
            ))

            recover from digest + signature.
 */
