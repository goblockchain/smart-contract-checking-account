pragma solidity ^0.4.18;

import './AccountAuthorizer.sol';
import './libs/StringUtils.sol';

contract AccountTransaction is AccountAuthorizer {
    
    using StringUtils for string;
    using StringUtils for bytes;

    // the minimum signatures for authorize the transaction
    uint256 public constant MIN_SIGNATURES_ADVISER = 2;
    uint256 public constant MIN_SIGNATURES_COLAB = 4;

    uint256 internal _transactionIdx;
    uint256 internal _transactionChangeContractOwnershipIdx;    

    //list the pending transations
    uint256[] public _pendingTransactions;
    uint256[] internal _pendingTransactionsChangeContractOwnership;

    mapping (uint256 => Transaction) internal _transactions;    
    mapping (uint256 => TransactionChangeContractOwnership) internal _transactionsChangeContractOwnership;    

    event TransactionSendTokenCreated(address from, address to, uint256 amount, uint256 transactionId);
    event TransactionSendTokenCompleted(address from, address to, uint256 amount, uint256 transactionId);
    event TransactionSendTokenSigned(address by, uint256 transactionId);

    event TransactionChangeContractOwnershipCreated(address from, address to, uint256 transactionId);
    event TransactionChangeContractOwnershipCompleted(address from, address to, uint256 transactionId);
    event TransactionChangeContractOwnershipSigned(address by, uint256 transactionId);

    //A struct to hold the Transaction's information about 
    // the transfering of tokens from an address to another
    struct Transaction {
        address from;
        address to;
        bytes description;
        uint256 amount;
        uint256 date;
        uint8 signatureCountColab;
        uint8 signatureCountAdviser;
        mapping (address => uint8) signaturesColabs;
        mapping (address => uint8) signaturesAdviser;
    }

    //A struct to hold the Transaction's information about 
    // the transfering of contract's ownership from an address to another
    struct TransactionChangeContractOwnership {
        address from;
        address to;
        uint256 amount;
        uint8 signatureCountColab;
        uint8 signatureCountAdviser;
        mapping (address => uint8) signaturesColabs;
        mapping (address => uint8) signaturesAdviser;
    } 

    //Modifier to validate the ownership
    modifier validOwner() {
        require(msg.sender == owner || _authorizers[msg.sender].statusAuthorizer == StatusAuthorizer.ACTIVE);
        _;
    }     

    //Get the transation to send tokens
    function getTransactionSendToken(uint256 _transactionId) public validOwner view 
                                            returns (address from, address to, uint256 amount, 
                                            string description, uint256 date, uint8 signatureCountColab, uint8 signatureCountAdviser) 
    {
        from = _transactions[_transactionId].from;
        to = _transactions[_transactionId].to;
        amount = _transactions[_transactionId].amount;
        description = _transactions[_transactionId].description.bytesToString();
        date = _transactions[_transactionId].date;
        signatureCountColab = _transactions[_transactionId].signatureCountColab;
        signatureCountAdviser = _transactions[_transactionId].signatureCountAdviser;
        return (from, to, amount, description, date, signatureCountColab, signatureCountAdviser);
    }

    //Sign a transaction to send tokens
    function signTransactionSendToken(uint256 _transactionId) public validOwner {

        Transaction storage transaction = _transactions[_transactionId];
        // Transaction must exist
        require(0x0 != transaction.from);
        // Creator cannot sign the transaction
        require(msg.sender != transaction.from);
        // Receiver cannot sign the transaction
        require(msg.sender != transaction.to);

        if (_authorizers[msg.sender].typeAuthorizer == TypeAuthorizer.COLAB) {
            // Cannot sign a transaction more than once
            assert(transaction.signaturesColabs[msg.sender] == 0);
            transaction.signaturesColabs[msg.sender] = 1;
            transaction.signatureCountColab++;
        } else {
            // Cannot sign a transaction more than once
            assert(transaction.signaturesAdviser[msg.sender] == 0);
            transaction.signaturesAdviser[msg.sender] = 1;
            transaction.signatureCountAdviser++;            
        }

        TransactionSendTokenSigned(msg.sender, _transactionId);

        if (transaction.signatureCountColab >= MIN_SIGNATURES_COLAB || transaction.signatureCountAdviser >= MIN_SIGNATURES_ADVISER ) {
            require(address(this).balance >= transaction.amount);
            TransactionSendTokenCompleted(transaction.from, transaction.to, 
                                            transaction.amount, _transactionId);
            deleteTransactionSendToken(_transactionId);
            //Convert amount in wei to ether base.
            uint256 etherAmount = transaction.amount * (10**18);
            transaction.to.transfer(etherAmount);
        }
    }

    //Delete a transaction to send tokens
    function deleteTransactionSendToken(uint256 _transactionId) private validOwner {
        uint8 replace = replaceElementFromTransactionsArray(_pendingTransactions, _transactionId);
        assert(replace == 1);
        delete _pendingTransactions[_pendingTransactions.length - 1];
        _pendingTransactions.length--;
    }

    //Get the pending transations to send tokens
    function getPendingTransactionsSendToken() public validOwner view returns (uint256[]) {
        return _pendingTransactions;
    }    

    //Get the transation to change Contract's ownership
    function getTransactionToChangeContractOwnership(uint256 _transactionId) public validOwner view 
                                            returns (address from, address to, uint256 amount, uint8 signatureCountColab, uint8 signatureCountAdviser) 
    {
        from = _transactionsChangeContractOwnership[_transactionId].from;
        to = _transactionsChangeContractOwnership[_transactionId].to;
        amount = _transactionsChangeContractOwnership[_transactionId].amount;
        signatureCountColab = _transactionsChangeContractOwnership[_transactionId].signatureCountColab;
        signatureCountAdviser = _transactionsChangeContractOwnership[_transactionId].signatureCountAdviser;

        return (from, to, amount, signatureCountColab, signatureCountAdviser);
    }

    //Get the pending transations to change Contract's ownership
    function getPendingTransactionsToChangeContractOwnership() public validOwner view returns (uint256[]) {
        return _pendingTransactionsChangeContractOwnership;
    }

    //Sign a transaction to change Contract's ownership
    function signTransactionToChangeContractOwnership(uint256 _transactionId) public validOwner {

        TransactionChangeContractOwnership storage transaction = _transactionsChangeContractOwnership[_transactionId];

        // Transaction must exist
        require(0x0 != transaction.from);
        // Receiver cannot sign the transaction
        require(msg.sender != transaction.to);
        // Creator cannot sign the transaction
        require(msg.sender != transaction.from);
        //check the type of authorizer
        if (_authorizers[msg.sender].typeAuthorizer == TypeAuthorizer.COLAB) {
            // Cannot sign a transaction more than once
            assert(transaction.signaturesColabs[msg.sender] == 0);
            transaction.signaturesColabs[msg.sender] = 1;
            transaction.signatureCountColab++;
        } else {
            // Cannot sign a transaction more than once
            assert(transaction.signaturesAdviser[msg.sender] == 0);
            transaction.signaturesAdviser[msg.sender] = 1;
            transaction.signatureCountAdviser++;            
        }
        TransactionChangeContractOwnershipSigned(msg.sender, _transactionId);
        if (transaction.signatureCountColab >= MIN_SIGNATURES_COLAB || transaction.signatureCountAdviser >= MIN_SIGNATURES_ADVISER ) {
            TransactionChangeContractOwnershipCompleted(transaction.from, transaction.to, _transactionId);
            owner = transaction.to;
            deleteTransactionChangeContractOwnership(_transactionId);
        }
    }
    
    //Delete a transaction to  change Contract's ownership
    function deleteTransactionChangeContractOwnership(uint256 _transactionId) private validOwner {
        uint8 replace = replaceElementFromTransactionsArray(_pendingTransactionsChangeContractOwnership, _transactionId);
        assert(replace == 1);
        delete _pendingTransactionsChangeContractOwnership[_pendingTransactionsChangeContractOwnership.length - 1];
        _pendingTransactionsChangeContractOwnership.length--;
    }      

    function replaceElementFromTransactionsArray(uint256[] storage _transactionsArray, uint256 _transactionId) 
        private returns (uint8) 
    {
        require(_transactionsArray.length > 0);
        uint8 replace = 0;

        for (uint256 i = 0; i < _transactionsArray.length; i++) {
            if (1 == replace) {
                _transactionsArray[i-1] = _transactionsArray[i];
            } else if (_transactionId == _transactionsArray[i]) {
                replace = 1;
            }
        }
        return replace;
    }
}