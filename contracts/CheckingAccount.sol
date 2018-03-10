pragma solidity ^0.4.18;

import "./zeppelin/Ownable.sol";

contract AccountAuthorizer {
    
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
    function addAccountAuthorizer(address authorized, int8 _typeAuthorizer) internal {
        require(_authorizers[authorized]._address == 0x0);
        _numAuthorized++;
    
        Authorizer memory authorizer;
        authorizer._address = authorized;
        authorizer.entryDate = now;
        authorizer.statusAuthorizer = StatusAuthorizer.ACTIVE;
        if (_typeAuthorizer == 1) {
            authorizer.typeAuthorizer = TypeAuthorizer.COLAB;
        } else {
            authorizer.typeAuthorizer = TypeAuthorizer.ADVISER;
        }
        
        _authorizers[authorized] = authorizer;
    }
    
    //Remove transaction's authorizer
    function removeAccountAuthorizer(address authorized) internal {
         _authorizers[authorized].statusAuthorizer = StatusAuthorizer.INACTIVE;
         if (_numAuthorized > 0) {
            _numAuthorized--;
         }
    }
}

contract CheckingAccount is Ownable, AccountAuthorizer {

    //A struct to hold the Transaction's information about 
    // the transfering of tokens from an address to another
    struct Transaction {
        address from;
        address to;
        bytes32 description;
        uint256 amount;
        uint256 date;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    //A struct to hold the Transaction's information about 
    // the transfering of contract's ownership from an address to another
    struct TransactionChangeContractOwnership {
        address from;
        address to;
        uint256 amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    // the minimum signatures for authorize the transaction
    uint256 private constant MIN_SIGNATURES = 2;
    //the max authorize to add in contract
    uint256 private constant MAX_AUTHORIZERS = 9;

    uint256 private _transactionIdx;
    uint256 private _transactionChangeContractOwnershipIdx;    

    //list the pending transations
    uint256[] private _pendingTransactions;
    uint256[] private _pendingTransactionsChangeContractOwnership;

    mapping(address => uint8) private _owners;
    mapping (uint256 => Transaction) private _transactions;    
    mapping (uint256 => TransactionChangeContractOwnership) private _transactionsChangeContractOwnership;

    //Modifier to validate the ownership
    modifier validOwner() {
        require(msg.sender == owner || _authorizers[msg.sender].statusAuthorizer == StatusAuthorizer.ACTIVE);
        _;
    }

    event DepositFunds(address from, uint256 amount);

    event TransactionSendTokenCreated(address from, address to, uint256 amount, uint256 transactionId);
    event TransactionSendTokenCompleted(address from, address to, uint256 amount, uint256 transactionId);
    event TransactionSendTokenSigned(address by, uint256 transactionId);

    event TransactionChangeContractOwnershipCreated(address from, address to, uint256 transactionId);
    event TransactionChangeContractOwnershipCompleted(address from, address to, uint256 transactionId);
    event TransactionChangeContractOwnershipSigned(address by, uint256 transactionId);
    
    function CheckingAccount() public {
        _numAuthorized = 0;
        owner = msg.sender;
    }

    //Receive tokens for the contract
    function() public payable {
        DepositFunds(msg.sender, msg.value);
    }

    function addAuthorizer(address authorized, int8 _typeAuthorizer) public onlyOwner {
        require(_numAuthorized <= MAX_AUTHORIZERS);
        addAccountAuthorizer(authorized, _typeAuthorizer);
    }

    function removeAuthorizer(address authorized)  public onlyOwner {
        require(_numAuthorized > 0);
        removeAccountAuthorizer(authorized);
    }

    //Request tokens withdraw
    function withdraw(uint256 amount, bytes32 description) public {
        transferTo(msg.sender, amount, description);
    }

    //Transfer tokens from Contract's balance to another address
    function transferTo(address to, uint256 amount, bytes32 description) private {
        require(address(this).balance >= amount);
        uint256 transactionId = _transactionIdx++;

        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.description = description;
        transaction.date = now;
        transaction.signatureCount = 0;

        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);

        TransactionSendTokenCreated(transaction.from, to, amount, transactionId);
    }

    //Get the pending transations to send tokens
    function getPendingTransactionsSendToken() public validOwner view returns (uint256[]) {
        return _pendingTransactions;
    }

    //Get the transation to send tokens
    function getTransactionSendToken(uint256 transactionId) public validOwner view 
                                            returns (address from, address to, uint256 amount, 
                                            bytes32 description, uint256 date, uint8 signatureCount) 
    {
        from = _transactions[transactionId].from;
        to = _transactions[transactionId].to;
        amount = _transactions[transactionId].amount;
        description = _transactions[transactionId].description;
        date = _transactions[transactionId].date;
        signatureCount = _transactions[transactionId].signatureCount;
    }

    //Sign a transaction to send tokens
    function signTransactionSendToken(uint256 transactionId) public validOwner {

        Transaction storage transaction = _transactions[transactionId];

        // Transaction must exist
        require(0x0 != transaction.from);
        // Creator cannot sign the transaction
        require(msg.sender != transaction.from);
        // Cannot sign a transaction more than once
        require(transaction.signatures[msg.sender] == 0);

        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        TransactionSendTokenSigned(msg.sender, transactionId);

        if (transaction.signatureCount >= MIN_SIGNATURES) {
            require(address(this).balance >= transaction.amount);
            transaction.to.transfer(transaction.amount);
            TransactionSendTokenCompleted(transaction.from, transaction.to, 
                                            transaction.amount, transactionId);
            deleteTransactionSendToken(transactionId);
        }
    }

    //Delete a transaction to send tokens
    function deleteTransactionSendToken(uint256 transactionId) public validOwner {
        uint8 replace = replaceElementFromTransactionsArray(_pendingTransactions, transactionId);
        assert(replace == 1);
        delete _pendingTransactions[_pendingTransactions.length - 1];
        _pendingTransactions.length--;
        delete _transactions[transactionId];
    }

    //Transfer Contract's ownership to another address
    function transferContractOwnershipTo(address to) public onlyOwner {
        uint256 transactionId = _transactionChangeContractOwnershipIdx++;

        TransactionChangeContractOwnership memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.signatureCount = 0;

        _transactionsChangeContractOwnership[transactionId] = transaction;
        _pendingTransactionsChangeContractOwnership.push(transactionId);

        TransactionChangeContractOwnershipCreated(msg.sender, to, transactionId);
    }

    //Get the pending transations to change Contract's ownership
    function getPendingTransactionsToChangeContractOwnership() public validOwner view returns (uint256[]) {
        return _pendingTransactionsChangeContractOwnership;
    }

    //Get the transation to change Contract's ownership
    function getTransactionToChangeContractOwnership(uint256 transactionId) public validOwner view 
                                            returns (address from, address to, uint256 amount, uint8 signatureCount) 
    {
        from = _transactionsChangeContractOwnership[transactionId].from;
        to = _transactionsChangeContractOwnership[transactionId].to;
        amount = _transactionsChangeContractOwnership[transactionId].amount;
        signatureCount = _transactionsChangeContractOwnership[transactionId].signatureCount;
    }

    //Sign a transaction to change Contract's ownership
    function signTransactionToChangeContractOwnership(uint256 transactionId) public validOwner {

        TransactionChangeContractOwnership storage transaction = _transactionsChangeContractOwnership[transactionId];

        // Transaction must exist
        require(0x0 != transaction.from);
        // Receiver cannot sign the transaction
        require(msg.sender != transaction.to);
        // Creator cannot sign the transaction
        require(msg.sender != transaction.from);
        // Cannot sign a transaction more than once
        require(transaction.signatures[msg.sender] == 0);

        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        TransactionChangeContractOwnershipSigned(msg.sender, transactionId);

        if (transaction.signatureCount >= ((MIN_SIGNATURES/2)+1)) {
            owner = transaction.to;
            TransactionChangeContractOwnershipCompleted(transaction.from, transaction.to, transactionId);
            deleteTransactionChangeContractOwnership(transactionId);
        }
    }

    //Delete a transaction to  change Contract's ownership
    function deleteTransactionChangeContractOwnership(uint256 transactionId) public validOwner {
        uint8 replace = replaceElementFromTransactionsArray(_pendingTransactionsChangeContractOwnership, transactionId);

        assert(replace == 1);
        delete _pendingTransactionsChangeContractOwnership[_pendingTransactionsChangeContractOwnership.length - 1];
        _pendingTransactionsChangeContractOwnership.length--;
        delete _transactionsChangeContractOwnership[transactionId];
    }

    function replaceElementFromTransactionsArray(uint256[] storage transactionsArray, uint256 transactionId) 
        private returns (uint8) 
    {
        require(transactionsArray.length > 0);
        uint8 replace = 0;

        for (uint256 i = 0; i < transactionsArray.length; i++) {
            if (1 == replace) {
                transactionsArray[i-1] = transactionsArray[i];
            } else if (transactionId == transactionsArray[i]) {
                replace = 1;
            }
        }
        return replace;
    }

    function walletBalance() public constant returns (uint256) {
        return address(this).balance;
    }
}