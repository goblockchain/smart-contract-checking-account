pragma solidity ^0.4.18;

import './Assert.sol';
import '../contracts/libs/StringUtils.sol';

contract TestStringUtils {

    using StringUtils for string;
    using StringUtils for bytes;

    string private _string = 'stringToBytes';

    function testStringToBytes() {
        bytes memory _bytes =  bytes(_string);
        bytes  memory result = _string.stringToBytes();
        Assert.equal(string(_bytes), string(result), "The String should be converted to Bytes");
    }

     function testBytesToString() {
        bytes memory _bytes =  bytes(_string);
        string memory result = _bytes.bytesToString();
        Assert.equal(result, _string, "The Bytes should be converted to String");
     }
}