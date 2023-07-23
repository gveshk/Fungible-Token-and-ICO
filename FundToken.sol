// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract maths{

    //This function calculates the tokens that has to be burned, 
    //the transaction fees is set to be 5% from which half is burned and other half is sent to treasury
    function burnCalc (uint a, uint b) public pure returns (uint c){
        require(a > 0);
        c = (a * b)/200;
    }

    //This function calculates the tokens that has to be sent to treasury, 
    //the transaction fees is set to be 5% from which half is sent to treasury and other half is burned
    function treasuryAmt(uint a, uint b) public pure returns(uint c) {
        require(a > 0);
        c = (a * b)/ 200;
    }
}

contract FundToken is ERC20, maths{
    //TransactionFees is set to be 5% and half of it will be burned while the other half will get added to treasury
    uint256 public constant TRANSACTION_FEES = 5; 

    //Total Supply of FDT tokens
    uint256 public TOTAL_SUPPLY;

    // Token supply of FDT tokens apart from ICO  
    uint256 public TOKEN_SUPPLY;

    //Tokens allocated for ICO
    uint256 public ICO_SUPPLY;

    address public immutable OWNER;
    address public immutable TREASURY;

    //Transaction fees is set False before ICO, After ICO is completed, Owner can enable the transaction fees
    bool public isTransactionFeesEnabled = false;

    event TransactionFeesSet(bool isTransactionFeesEnabled);
 
    constructor(address _owner, address _treasury, address _ICOaddress) ERC20("FundToken", "FDT"){
        TOKEN_SUPPLY = 70000000 ether;
        ICO_SUPPLY = 30000000 ether;
        TOTAL_SUPPLY = TOKEN_SUPPLY + ICO_SUPPLY;
        OWNER = _owner;
        TREASURY = _treasury;
        _mint(_owner, TOKEN_SUPPLY);
        _mint(_ICOaddress,ICO_SUPPLY);
    }

    //This function is to enable the transaction Fees, which is set to be 5%
    //Only owner can call this function
    function setTransactionFees(bool newValue) external {
        require(msg.sender == OWNER, "only owner allowed");
        
        isTransactionFeesEnabled = newValue;
        emit TransactionFeesSet(isTransactionFeesEnabled);
    }

    //This is the transfer function
    function _transfer(
        address from,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 amountToRecipient = amount;
        uint256 amountToTreasury = 0;
        uint256 tokenBurn = 0;

        if (isTransactionFeesEnabled) {
            amountToRecipient =
                amountToRecipient -
                (amount * TRANSACTION_FEES) /
                100;
            tokenBurn = burnCalc(amount, TRANSACTION_FEES);
            amountToTreasury = treasuryAmt(amount, TRANSACTION_FEES);
            super._transfer(from, TREASURY, amountToTreasury);
            super._burn(from,tokenBurn);
        }
        super._transfer(from, recipient, amountToRecipient);
    }
}
