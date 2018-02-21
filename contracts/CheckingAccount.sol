pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";


contract CheckingAccount is Ownable {

    //A struct to hold the Authorizer's informations
    struct Authorizer {
        address _address;
        uint entryDate;
        uint8 status; // 0 - Inactive | 1 - Active
    }

    //A struct to hold the Transaction's information about 
    // the transfering of tokens from an address to another
    struct Transaction {
        address from;
        address to;
        bytes32 description;
        uint amount;
        uint date;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    //A struct to hold the Transaction's information about 
    // the transfering of contract's ownership from an address to another
    struct TransactionChangeContractOwnership {
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    uint private constant MIN_SIGNATURES = 2;
    uint private constant MAX_AUTHORIZERS = 9;
    uint private _transactionIdx;
    uint private _transactionChangeContractOwnershipIdx;
    uint private _numAuthorized;

    uint[] private _pendingTransactions;
    uint[] private _pendingTransactionsChangeContractOwnership;

    address private _owner;

    mapping(address => Authorizer) private _authorizers;
    mapping(address => uint8) private _owners;
    mapping (uint => Transaction) private _transactions;
    mapping (uint => TransactionChangeContractOwnership) private _transactionsChangeContractOwnership;

    //Modifier to validate the ownership
    modifier validOwner() {
        require(msg.sender == _owner || _authorizers[msg.sender].status == 1);
        _;
    }

    event DepositFunds(address from, uint amount);
    event TransactionSendTokenCreated(address from, address to, uint amount, uint transactionId);
    event TransactionSendTokenCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSendTokenSigned(address by, uint transactionId);

    event TransactionChangeContractOwnershipCreated(address from, address to, uint transactionId);
    event TransactionChangeContractOwnershipCompleted(address from, address to, uint transactionId);
    event TransactionChangeContractOwnershipSigned(address by, uint transactionId);

    function CheckingAccount() public {
        _numAuthorized = 0;
        _owner = msg.sender;
    }

    //Receive tokens for the contract
    function() public payable {
        DepositFunds(msg.sender, msg.value);
    }

    //Add transaction's authorizer
    function addAuthorizer(address authorized) public onlyOwner {
        require(_numAuthorized <= MAX_AUTHORIZERS);

        if (_authorizers[authorized]._address == 0x0) {
            _numAuthorized++;
        }
        Authorizer memory authorizer;
        authorizer._address = authorized;
        authorizer.entryDate = now;
        authorizer.status = 1;
        _authorizers[authorized] = authorizer;
    }
    
    //Remove transaction's authorizer
    function removeAuthorizer(address authorized) public onlyOwner {
         _authorizers[authorized].status = 0;
         if (_numAuthorized > 0) {
            _numAuthorized--;
         }
    }

    //Request tokens withdraw
    function withdraw(uint amount, bytes32 description) public {
        transferTo(msg.sender, amount, description);
    }

    //Transfer tokens from Contract's balance to another address
    function transferTo(address to, uint amount, bytes32 description) private {
        require(address(this).balance >= amount);
        uint transactionId = _transactionIdx++;

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
    function getPendingTransactionsSendToken() public validOwner view returns (uint[]) {
        return _pendingTransactions;
    }

    //Get the transation to send tokens
    function getTransactionSendToken(uint transactionId) public validOwner view 
                                            returns (address from, address to, uint amount, 
                                            bytes32 description, uint date, uint8 signatureCount) 
    {
        from = _transactions[transactionId].from;
        to = _transactions[transactionId].to;
        amount = _transactions[transactionId].amount;
        description = _transactions[transactionId].description;
        date = _transactions[transactionId].date;
        signatureCount = _transactions[transactionId].signatureCount;
    }

    //Sign a transaction to send tokens
    function signTransactionSendToken(uint transactionId) public validOwner {

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
    function deleteTransactionSendToken(uint transactionId) public validOwner {
        uint8 replace = replaceElementFromTransactionsArray(_pendingTransactions, transactionId);
        assert(replace == 1);
        delete _pendingTransactions[_pendingTransactions.length - 1];
        _pendingTransactions.length--;
        delete _transactions[transactionId];
    }

    //Transfer Contract's ownership to another address
    function transferContractOwnershipTo(address to) public onlyOwner {
        uint transactionId = _transactionChangeContractOwnershipIdx++;

        TransactionChangeContractOwnership memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.signatureCount = 0;

        _transactionsChangeContractOwnership[transactionId] = transaction;
        _pendingTransactionsChangeContractOwnership.push(transactionId);

        TransactionChangeContractOwnershipCreated(msg.sender, to, transactionId);
    }

    //Get the pending transations to change Contract's ownership
    function getPendingTransactionsToChangeContractOwnership() public validOwner view returns (uint[]) {
        return _pendingTransactionsChangeContractOwnership;
    }

    //Get the transation to change Contract's ownership
    function getTransactionToChangeContractOwnership(uint transactionId) public validOwner view 
                                            returns (address from, address to, uint amount, uint8 signatureCount) 
    {
        from = _transactionsChangeContractOwnership[transactionId].from;
        to = _transactionsChangeContractOwnership[transactionId].to;
        amount = _transactionsChangeContractOwnership[transactionId].amount;
        signatureCount = _transactionsChangeContractOwnership[transactionId].signatureCount;
    }

    //Sign a transaction to change Contract's ownership
    function signTransactionToChangeContractOwnership(uint transactionId) public validOwner {

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
            _owner = transaction.to;
            TransactionChangeContractOwnershipCompleted(transaction.from, transaction.to, transactionId);
            deleteTransactionChangeContractOwnership(transactionId);
        }
    }

    //Delete a transaction to  change Contract's ownership
    function deleteTransactionChangeContractOwnership(uint transactionId) public validOwner {
        uint8 replace = replaceElementFromTransactionsArray(_pendingTransactionsChangeContractOwnership, transactionId);

        assert(replace == 1);
        delete _pendingTransactionsChangeContractOwnership[_pendingTransactionsChangeContractOwnership.length - 1];
        _pendingTransactionsChangeContractOwnership.length--;
        delete _transactionsChangeContractOwnership[transactionId];
    }

    function replaceElementFromTransactionsArray(uint[] storage transactionsArray, uint transactionId) 
        private returns (uint8) 
    {
        require(transactionsArray.length > 0);
        uint8 replace = 0;

        for (uint i = 0; i < transactionsArray.length; i++) {
            if (1 == replace) {
                transactionsArray[i-1] = transactionsArray[i];
            } else if (transactionId == transactionsArray[i]) {
                replace = 1;
            }
        }
        return replace;
    }

    function walletBalance() public constant returns (uint) {
        return address(this).balance;
    }
}