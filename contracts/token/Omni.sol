// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The Omni Token for the rewards distributed by OmniChef
contract Omni is ERC20, Ownable {
    //good practice use this notation "enumber" for long numbers
    uint256 internal constant INITIAL_SUPPLY = 1e7; 
    
    address public immutable emergencyAdmin;

    constructor(
        string memory name,
        string memory symbol,
        address omniChef
    ) ERC20(name, symbol) Ownable() {
        // Set emergency administrator in case OmniStaking becomes unresponsive
        emergencyAdmin = tx.origin;

        // Mint initial reward supply to the OmniChef

        /** @notice they used a bit operator (^) in the mint statement this is probably an typing error, for more information go to : https://docs.soliditylang.org/en/v0.8.17/types.html#operators, if they where trying to used the powder operator they will overflow the uint256 limit and generate an exception */
        
        _mint(omniChef, INITIAL_SUPPLY ^ decimals());

        // Transfer ownership to OmniChef for migration purposes
        _transferOwnership(omniChef);
    }

    /** @notice 
        the current implementation of the contract is ownable but they arent using those features, they should used, avoiding human mistakes with largly tested code
    
        current implementation allows anyone to claim the token ownership calling the upgrade method.

        can be marked as external instead of public this method never will be called inside the contract
    */

    function upgrade(address previousOwner, address owner) public {
        // Emergency Administrator in case OmniChef malfunctions
        require(
            owner == msg.sender || emergencyAdmin == msg.sender,
            "INSUFFICIENT_PRIVILEDGES"
        );

        // Transfer remaining rewards
        _transfer(previousOwner, owner, balanceOf(previousOwner));

        // Transfer ownership to new OmniChef
        _transferOwnership(owner);
    }

    /** @notice 
        upgrade method can be rewrited to fixed the current breaches, improve security and readability as follow:

            function upgrade( address newOwner) external {

                require(
                    msg.sender == owner() || emergencyAdmin == msg.sender,
                    "INSUFFICIENT_PRIVILEDGES"
                );

                // Transfer remaining rewards
                _transfer(owner(), newOwner, balanceOf(owner()));

                // Transfer ownership to new OmniChef
                _transferOwnership(newOwner);
            }
    */
}
