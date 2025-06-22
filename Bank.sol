//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Bank {

    enum TXtype {deposit, withdrawal, transfer}

    struct Account {
        address owner;
        uint balance;
        uint loans;
        uint since;
    }
    struct Transaction {
        address sender;
        address receiver;
        uint amount;
        uint timestamp;
        TXtype txType;
    }

    //Transaction[] public transactions;
    mapping(address => bool) public hasRegistered;
    mapping(address => Account) public accounts;
    mapping(address => Transaction[]) public txnsOfAddress;
    
    function register(address newAccountOwner) external {
        require (!hasRegistered[newAccountOwner], "only one account per address");
        require (msg.sender == newAccountOwner);

        accounts[newAccountOwner] = Account(newAccountOwner, 0, 0, block.timestamp);
        hasRegistered[newAccountOwner] = true;
    }

    function deposit( ) external payable {
        require(hasRegistered[msg.sender]);


        Account storage account = accounts[msg.sender];
        account.balance += msg.value;

        Transaction memory newTX = Transaction({
            sender: msg.sender,
            receiver: address(this),
            amount: msg.value,
            timestamp: block.timestamp,
            txType: TXtype.deposit
        });

        txnsOfAddress[msg.sender].push(newTX);
    }

    function withdrawal(Account memory _account, uint withdrawAmount) external {
        require (msg.sender == _account.owner, "only account holder can withdraw");
        require (withdrawAmount <= _account.balance); 

        (bool withdrawn, ) = _account.owner.call{value: withdrawAmount}("");
        require (withdrawn);

        _account.balance -= withdrawAmount;

        Transaction memory newTX = Transaction({
            sender: address(this),
            receiver: _account.owner,
            amount: withdrawAmount,
            timestamp: block.timestamp,
            txType: TXtype.withdrawal
        });

        txnsOfAddress[_account.owner].push(newTX);
    }

    function transfer(Account memory sender, Account memory receiver, uint transferAmount) external {
        require (hasRegistered[msg.sender], "only a registered account can transfer through bank");
        require (hasRegistered[receiver.owner], "sender doesnt own an account");

        (bool transferred, ) = receiver.owner.call{value: transferAmount}("");
        require(transferred);

        receiver.balance += transferAmount;
        sender.balance -= transferAmount;

        Transaction memory newTX = Transaction({
            sender: sender.owner,
            receiver: receiver.owner,
            amount: transferAmount,
            timestamp: block.timestamp,
            txType: TXtype.transfer
        });

        txnsOfAddress[sender.owner].push(newTX);
    }

    //loops through arrays can be expensive
    function viewTxnsOf(address _accountHolder) public view returns (Transaction[] memory){
        return txnsOfAddress[_accountHolder];
    }
}