// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/SafeArithmetics.sol";

// Minimal CEth interface, see https://etherscan.io/address/0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5#code
interface ICEth {
    function redeem(uint256) external;

    function accrueInterest() external;

    function balanceOfUnderlying(address owner) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

// Manages an ETH native balance to interact with the Compound protocol: https://compound.finance/docs#getting-started

/** @notice this contracts manages assets they should added a basic access control mechanism, otherwise anyone who found this contract will be able to call the compound method and steal the assets from it.  for more info can read: 
    https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

    -this contract is handlin ethers they should have a method to pull the ethers out.  

*/


contract OmniCompoundStrategy {
    using SafeArithmetics for uint256;

    ICEth private CEth;

    constructor(address _CEth) {
        CEth = ICEth(_CEth);
    }

    /** 
        Deposit funds into the Compound ERC20 token
        @dev this method is sending eth into compound porotocol, internally compound will receive this eth and call the callback method to mint Ceth tokens 
        The user receives a quantity of cTokens equal to the underlying tokens supplied, divided by the current Exchange Rate.

        @notice this method will achive his goal, but this implementation can failed or misbehave depending on the contract implementation, compounds contracts expose a mint menthod, this method is called on the callback method, but is a better pratice to used the expose method from the contract for more info: compunds docs : https://docs.compound.finance/v2/ctokens/#mint
    */

    function deposit() public {
        _send(payable(address(CEth)), address(this).balance);
    }

    /**
        Compound funds acquired from interest on Compound

        @notice when the method compound calls _unlock method the contracts eth balance value should be zero, why they call deposit again? if they want to make sure the contract wont holds eth they can used  _send(address(this).balance) inside of _unlock method declarataion and avoid the deposit call in compound saving gas fees
    */

    function compound() external {
        CEth.accrueInterest();
        _unlock(balance());
        deposit();
    }

    // Calculate total balance
    function balance() public view returns (uint256) {
        return address(this).balance + CEth.balanceOfUnderlying(address(this));
    }

    /** 
        @dev this method should have a brief explanation
        @dev should be marked as internal because is never called from the aoutside of the contact
        @param amount = should add a param explanation     
    */

    function _unlock(uint256 amount) public {

        if (amount > address(this).balance)

            CEth.redeem(
                (amount - address(this).balance) //this is the same as "balanceOfUnderlying"
                    .safe(
                        SafeArithmetics.Operation.MUL,
                        CEth.balanceOf(address(this))
                    )
                    .safe(
                        SafeArithmetics.Operation.DIV,
                        CEth.balanceOfUnderlying(address(this))
                    )
            );

            /** @notice 
            
                at this point we known this:
                @param amount == address(this).balance + CEth.balanceOfUnderlying(address(this))
                
                therefore: 
                    amount - address(this).balance == CEth.balanceOfUnderlying(address(this))

                at this point @param amount == CEth.balanceOfUnderlying(address(this))
            
                them:
                
                    @param amount * CEth.balanceOf(address(this))

                divided by : 
                
                CEth.balanceOfUnderlying(address(this))

                is: 
                
                CEth.balanceOf(address(this))

                long story short we are calling:

                CEth.redeem(CEth.balanceOf(address(this)));

             */


        _send(payable(msg.sender), amount);
    }

    /**
    
        ALTERNATIVE _unlock METHOD IMPLEMENTATION (WITH THE MATH OPERATIONS SIMPLIFIED)
    
         function _unlock(uint256 amount) internal {

             if (amount > address(this).balance)
                CEth.redeem(CEth.balanceOf(address(this)));
                _send(payable(msg.sender), amount);
         }
    
    */

    /**
        @param target = should add a param explanation
        @param amount = should add a param explanation
        "_send" method is handling plain ether so we can rewrited to follow the latest solidity recomendations showed here https://solidity-by-example.org/sending-ether/
     */
    function _send(address payable target, uint256 amount) internal {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = target.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
