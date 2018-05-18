pragma solidity ^0.4.18;

import "./AccountTransaction.sol";

contract CheckingAccount is AccountTransaction {

    event DepositFunds(address from, uint256 amount);
    
    function CheckingAccount() public {
        _numAuthorized = 0;
        owner = msg.sender;
        addAuthorizer(msg.sender, TypeAuthorizer.ADVISER);
    }

    //Receive tokens for the contract
    function() public payable {
        emit DepositFunds(msg.sender, msg.value);
    }

    //Request tokens withdraw
    function withdraw(uint256 _amount, bytes32 _description) public onlyAuthorizer {
        require(_amount > 0);
        transferTo(msg.sender, _amount, _description);
    }

    //Transfer Contract's ownership to another address
    function transferContractOwnershipTo(address _to) public onlyOwner {
        require(address(_to) != 0x0);
        uint256 transactionId = _transactionChangeContractOwnershipIdx++;

        TransactionChangeContractOwnership memory transaction;
        transaction.from = msg.sender;
        transaction.to = _to;
        transaction.signatureCountColab = 0;
        transaction.signatureCountAdviser = 0;

        _transactionsChangeContractOwnership[transactionId] = transaction;
        _pendingTransactionsChangeContractOwnership.push(transactionId);

        emit TransactionChangeContractOwnershipCreated(msg.sender, _to, transactionId);
    }  

    function walletBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //Transfer tokens from Contract's balance to another address
    function transferTo(address _to, uint256 _amount, bytes32 _description) private {
        require(_amount >= 0);
        require(address(this).balance >= _amount);
        
        uint256 transactionId = _transactionIdx++;

        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.description = _description;
        transaction.date = now;
        transaction.signatureCountColab = 0;
        transaction.signatureCountAdviser = 0;
        transaction.statusTransaction = StatusTransaction.WAITING;

        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);

        emit TransactionSendTokenCreated(transaction.from, _to, _amount, transactionId);
    }
}