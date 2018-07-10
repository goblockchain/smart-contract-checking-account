pragma solidity ^0.4.21;

import "./zeppelin/Ownable.sol";

contract AccountAuthorizer is Ownable {
    
    //the max authorize to add in contract
    uint256 public MAX_AUTHORIZERS = 10;

    // 0 - Inactive | 1 - Active
    enum StatusAuthorizer {INACTIVE, ACTIVE}
    StatusAuthorizer statusAuthorizer;

    // 0 - COLAB | 1 - ADVISER
    enum TypeAuthorizer {COLAB, ADVISER}
    TypeAuthorizer typeAuthorizer;

    uint256 public _numAuthorized;    
    mapping(address => Authorizer) public _authorizers;

    modifier onlyAuthorizer() {
        require(
            _authorizers[msg.sender]._address != 0x0 && 
            _authorizers[msg.sender].statusAuthorizer == StatusAuthorizer.ACTIVE
        );
        _;
    }

    //A struct to hold the Authorizer's informations
    struct Authorizer {
        address _address;
        uint256 entryDate;
        StatusAuthorizer statusAuthorizer;
        TypeAuthorizer typeAuthorizer;
    }

    //Add transaction's authorizer
    function addAuthorizer(address _authorized, TypeAuthorizer _typeAuthorizer) public onlyOwner {
        require(_numAuthorized <= MAX_AUTHORIZERS);
        require(
            _authorizers[_authorized]._address == 0x0 || 
            _authorizers[_authorized].statusAuthorizer == StatusAuthorizer.INACTIVE
        );

        _numAuthorized++;
    
        Authorizer memory authorizer;
        authorizer._address = _authorized;
        authorizer.entryDate = now;
        authorizer.statusAuthorizer = StatusAuthorizer.ACTIVE;
        authorizer.typeAuthorizer = _typeAuthorizer;
        _authorizers[_authorized] = authorizer;
    }
    
    //Remove transaction's authorizer
    function removeAuthorizer(address _authorized) public onlyOwner {
        require(_numAuthorized > 0);
        _authorizers[_authorized].statusAuthorizer = StatusAuthorizer.INACTIVE;
        if (_numAuthorized > 0) {
            _numAuthorized--;
        }
    }

    // Allows the current owner to transfer control of the contract to a newOwner.
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0) &&
            _authorizers[newOwner].statusAuthorizer == StatusAuthorizer.ACTIVE
        );

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }    
}