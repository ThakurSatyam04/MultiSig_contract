// This smart contract make sure that the transaction happens between one sender and one receiver will get signed by more than one owner

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract MultiSig
{
    address[] public owners; // The array of addresses of all the owners
    uint public numConfirmationRequired; // Keep the count that how much confirmation required

    struct Transaction{
        // Struct to keep track of all the details of the transactions
        address to;
        uint value;
        bool executed;
    }

    mapping(uint => mapping(address=>bool)) isConfirmed;
    Transaction[] public transactions; // Array of object to store more than one struct data.

    event TransactionSubmitted(uint transactionId, address sender, address receiver, uint amount);

    event TransactionConfirmed(uint transactionId);

    event TransactionExecuted(uint _transactionsId);

    constructor(address[] memory _owners, uint _numConfirmationRequired){
        require(_owners.length > 1, "Number of owner must be more than 1");
        require(_numConfirmationRequired>0 && numConfirmationRequired<=_owners.length, "Number of confirmation are not in sinc with the number of owners");

        // We need to check if the owner's address passed in the function are valid or not,
        // If the address is valid push it to the owners address ( state "owner" varible )
        for(uint i=0;i<_owners.length;i++){
            require(_owners[i] != address(0), "Invalid Owner address"); // address(0) means empty address
            owners.push(_owners[i]); 
        }

        numConfirmationRequired = _numConfirmationRequired;
    }

    function submitTransaction(address _to) public payable {
        require(_to != address(0), "Invalid Receiver's Address");
        require(msg.value > 0, " Transfer amount must be greater than 0");

        uint transactionId = transactions.length;
        transactions.push(Transaction({to:_to,value:msg.value,executed:false}));
        emit TransactionSubmitted(transactionId,msg.sender,_to,msg.value);
    }

    function confirmTransaction(uint _transactionId) public {
        require(_transactionId<transactions.length, "Invalid transaction Id");
        require(!isConfirmed[_transactionId][msg.sender], "transaction is already confirmed by the Owner");

        isConfirmed[_transactionId][msg.sender] = true;

        emit TransactionConfirmed(_transactionId);

        if(isTransactionConfirmed(_transactionId)) {
            executeTransaction(_transactionId);
        }
    }

    function executeTransaction(uint _transactionId) public payable {
        // we are making this function payable because this function is transfering fund to particular address.
        require(_transactionId<transactions.length, "Invalid transaction Id");
        require(!transactions[_transactionId].executed, "Transaction is already executed");

        (bool success,) = transactions[_transactionId].to.call{value: transactions[_transactionId].value}("");
        require(success, "Transaction Execution failed");
        transactions[_transactionId].executed = true;
        emit TransactionExecuted(_transactionId);

    }

    function isTransactionConfirmed(uint _transactionId) internal view returns(bool){
        require(_transactionId<transactions.length, "Invalid transaction Id");
        uint confirmationCount; // Initially zero

        for(uint i=0;i<owners.length;i++){
            if(isConfirmed[_transactionId][owners[i]]){
                confirmationCount++;
            }
        }

        return confirmationCount >= numConfirmationRequired;
    }
}