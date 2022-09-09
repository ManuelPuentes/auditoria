// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


/**
  @notice pragma statement bad practice:
  Contracts should be deployed with the same compiler version and flags that they have been tested the most with. Locking the pragma helps ensure that contracts do not accidentally get deployed using, for example, the latest compiler which may have higher risks of undiscovered bugs

    // bad
    pragma solidity ^0.4.4;


    // good
    pragma solidity 0.4.4;

  this contract can used the  openzeppelin access control mechanism :https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol 

  this will avoid the declaration of the restricted modifier and more features to handle the access managment 

  contract should initilize the variable values in the constructor explicitly

  setCompleted can be marked as external 

 */



contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}
