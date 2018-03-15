pragma solidity ^0.4.18;

import "./zeppelin/Ownable.sol";

contract AccountAuthorizer is Ownable {
    
    //the max authorize to add in contract
    uint256 public constant MAX_AUTHORIZERS = 9;

    // 0 - Inactive | 1 - Active
    enum StatusAuthorizer {INACTIVE, ACTIVE}
    StatusAuthorizer statusAuthorizer;

    // 0 - COLAB | 1 - ADVISER
    enum TypeAuthorizer {COLAB, ADVISER}
    TypeAuthorizer typeAuthorizer;

    uint256 public _numAuthorized;    
    mapping(address => Authorizer) public _authorizers;

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
        require(_authorizers[_authorized]._address == 0x0);
        _numAuthorized++;
    
        Authorizer memory authorizer;
        authorizer._address = _authorized;
        authorizer.entryDate = now;
        authorizer.statusAuthorizer = StatusAuthorizer.ACTIVE;
        authorizer.typeAuthorizer = _typeAuthorizer;
        
        _authorizers[_authorized] = authorizer;
    }
    
    //Remove transaction's authorizer
    function removeAuthorizer(address _authorized)  public onlyOwner {
        require(_numAuthorized > 0);
        _authorizers[_authorized].statusAuthorizer = StatusAuthorizer.INACTIVE;
        if (_numAuthorized > 0) {
            _numAuthorized--;
        }
    }
}
