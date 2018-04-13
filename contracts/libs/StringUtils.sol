pragma solidity ^0.4.18;

/**
 * @title StringUtils
 * @dev The StringUtils library provides functions to convert string to bytes and vice-versa.
 */
library StringUtils {

    function bytesToString(bytes _bytes) pure internal returns (string){
        bytes memory bytesArray = new bytes(_bytes.length);
        for (uint256 i; i < _bytes.length; i++) {
            bytesArray[i] = _bytes[i];
        }
        return string(_bytes);
    }

    function stringToBytes(string memory _string) pure internal  returns (bytes){
        bytes memory _bytes = bytes(_string);
        return _bytes;
    }
}
