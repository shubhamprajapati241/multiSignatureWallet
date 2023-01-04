// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

// A MultiSig wallet is a digital wallet that operates with multisignature addresses. 
//  multiple senders -> single receiver

// ? Functions flow
// * 1. submitTransaction >>> first owner submit the transaction => get the transaction id in 0 , 1
//* 2. confirmTransaction >>> rest owners will confirm the transaction with that particular transaction id
//* 3. executeTransaction >>> After confirmation : execute the transaction will happen 
//* 4. revokeConfirmation >>> with owners want to remove their confirmation


contract MultiSignWallet {

    // creating the events
    // event is used to log the details on the blockchain
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransactions(
        address indexed owner,
        uint indexed txIndexed,
        address indexed to,
        uint values,
        bytes data
    );

    event ConfirmTransactions(address indexed owner, uint indexed txIndex);
    event RevokeTransactions(address indexed owner, uint indexed txIndex);
    event ExecuteTransactions(address indexed owner, uint indexed txIndex);

    // Declaring the variables
    address[] public owners; // storing the owners
    mapping(address=> bool) public isOwner; // for checking the given address is owners or not 
    uint public numConfirmationsRequired; // how many confirmations are required for signing the transactions

    struct Transaction {
        address to; // receiver address
        uint value; // amount you want to send
        bytes data; // any text, msg along with the money
        bool executed; // to check whether the transaction is executed or not
        uint numConfirmations; // number of confirmation from the owners
    }

    mapping(uint=> mapping(address=>bool)) public isConfirmed; // for checking the status of a particular transactions
    // herer uint = transactions_id, address = owner, bool = approve or not approve 

    Transaction[] transactions;  // creating array of struct

    // Declaring the modifiers : Modifier work as the validation
    // 1. for checking owners or only the owner can call
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not the owner");
        _;
    }

    // 2. modifier to check the existance of the transactions
    modifier txExists(uint _txIndex){
        require(_txIndex < transactions.length, "Transactions doesn't exists.");
        // transactions array length is 4 and searching to _txIndex = 5 => This error will shown
        _;
    }

    // 3. For check the status of executed transactions
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Tx already confirmed");
        _;
    }

    // In constructor setting the owners and number of Confirmations for the transactions
    constructor(address[] memory _owners, uint _numConfirmationRequired) {
        require(_owners.length > 0, "At least one owner required");
        require(_numConfirmationRequired > 0 && _numConfirmationRequired >= owners.length, "Invalid number of required confirmations in constructor"); // _numConfirmationRequired should be greater than the 0 to less than the total number of owners

        for(uint i=0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner"); // owner not be empty address
            require(!isOwner[owner], "Owner not unique"); // for owner uniqueness
            isOwner[owner] = true;
            owners.push(owner); 
        }
        numConfirmationsRequired = _numConfirmationRequired;
    }

    function depositEth() public payable {
        (bool success, )  = address(this).call{value :msg.value}("");
        require(success, "Deposit Failed");
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    receive() external payable {}

    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) 
        notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations +=1; // ++transaction.numConfirmations
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransactions(msg.sender, _txIndex);
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;
        transactions.push(
            Transaction({
                to : _to, 
                value : _value,
                data : _data, 
                executed : false,
                numConfirmations : 0
            })   
        );

        emit SubmitTransactions(msg.sender, txIndex, _to, _value, _data);
    } 

    function excecuteTransaction(uint _txIndex) public onlyOwner 
    txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        // require(transaction.numConfirmations >= numConfirmationsRequired, "Cannot execute tansactions");
        transaction.executed = true;
        (bool success, )  = transaction.to.call{gas : 20000, value : transaction.value}(transaction.data);
        require(success, "Tx Failed");
        emit ExecuteTransactions(msg.sender, _txIndex);
    }

    //owner can revoke thier confirmation
    function revokeConfirmation(uint _txIndex) public 
        onlyOwner txExists(_txIndex) notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "Transaction is not confirmed");
        transaction.numConfirmations -=1;
        isConfirmed[_txIndex][msg.sender] = false;
        emit RevokeTransactions(msg.sender, _txIndex);
    }


    function getOwners() public view returns(address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns(uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view 
    returns(address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        Transaction storage transaction = transactions[_txIndex]; 
        return(transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations);
    }

    function getContractBalance() public view returns(uint) {
       return address(this).balance;
    }

}


// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
// 2 - confirmations means 2 / 3