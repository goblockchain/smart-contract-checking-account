// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract VerifySignature {
    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    /// @notice This function returns the same regardless of who's calling it (pure)
    /// return: 0xde04b3e97a340583644438433dfc02a1c389def22b3ed841f9a0204c77e81bf9
    /// goerli: hash = 0x3d9bef4d93a63d194967758b74b8cb66835d2dba655fb3eba4b1f840fcc7cb7b
    function getMessageHash(
        address _to,
        uint _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _message));
    }

    /* 3. Sign message hash
    # using browser
let hash = 0x3d9bef4d93a63d194967758b74b8cb66835d2dba655fb3eba4b1f840fcc7cb7b
let account = "0x14D9cF087648472410577cdbab62718f92bEB328"
ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x2c54219775e3aab84963db64fbf43e85abfda904e382a9b14186b3548b07d95d501b123f293f13d04becab2628c2d5a0ed1c30537c51e29cc3f6028792df5ac51c
    */
    /// for 0x...b2, signature is: 0xe35664ee982c1e215a442884ed7722762837a15a505e1bf3aad7c560afb33c645fa41f1f547b27edccbbde088d6c68b1c731c637879d94f654020810392f975f1b
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    /**
    * signer = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        to = 0x0fC5025C764cE34df352757e82f7B5c4Df39A836
        message = 0xde04b3e97a340583644438433dfc02a1c389def22b3ed841f9a0204c77e81bf9
        signature = 0xe35664ee982c1e215a442884ed7722762837a15a505e1bf3aad7c560afb33c645fa41f1f547b27edccbbde088d6c68b1c731c637879d94f654020810392f975f1b
    */
    function verify(
        address _signer,
        address _to,
        uint _message,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
