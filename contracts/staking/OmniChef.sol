// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/SafeArithmetics.sol";
import "../strategies/OmniCompoundStrategy.sol";
import "../token/Omni.sol";


/**
    @notice will be useful to have a detailed explanation of the contract goals, im assuming this contracts allows user to stake their assets and receive Omni tokens as interest over the time for then
*/

contract OmniChef is OmniCompoundStrategy, Ownable {
    using SafeArithmetics for uint256;

    address public constant CEth = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;


    /**@notice  they are using here the address of the current contract, but at this point this address can not be determinated, Omni instace should be initialized on the contructor method were this address can be determinated  */
    Omni public omni = new Omni("Omniscia Test Token", "OMNI", address(this));

    mapping(address => uint256) public times;
    mapping(address => uint256) public stakes;
    uint256 public totalStakes;

    constructor() Ownable() OmniCompoundStrategy(CEth) {}

    // Prevent Renouncation & Transfer of Ownership
    function renounceOwnership() public override {
        revert("NO_OP");
    }

    function transferOwnership(address newOwner) public override {
        revert("NO_OP");
    }

    // Staking Mechanisms
    receive() external payable {
        require(stake(msg.value) != 0, "STAKING_MALFUNCTION");
    }

    function stake() external payable returns (uint256) {
        return stake(msg.value);
    }

    function stake(uint256 value) public payable
        refund(value)
        returns (uint256)
    {
        stakes[msg.sender] = stakes[msg.sender].safe(
            SafeArithmetics.Operation.ADD,
            value
        );
        times[msg.sender] = block.timestamp;
        totalStakes = totalStakes.safe(SafeArithmetics.Operation.ADD, value);

        return stakes[msg.sender];
    }

    /** @notice this method should have a detailed explanation of the methods goals
        when the users calls to this method they are trying to claim the tokens they staked and the omni tokens rewards?

        if the assertion above is true:

        we should call _unlock(stakes[msg.sender]) but _unlock internally should call:
        
        function redeemUnderlying(uint redeemAmount) returns (uint)  
        docs:https://docs.compound.finance/v2/ctokens/#redeem-underlying

        like this:

        redeemUnderlying(stakes[msg.sender]);

        this method will retrieve (stakes[msg.sender]) amount of ethers in this case and we sended back to the msg.sender from here using: 
        
        _send(payable(msg.sender), stakes[msg.sender]);

        then we can call _reward(value);


        HERES THE _unlock METHOD IMPLEMENTATION:

        function _unlock(uint256 amount) internal {

            CEth.redeemUnderlying(amount);
            _send(payable(msg.sender), amount);
        
        }

        and from this contract just need to do this:

        _send(payable(msg.sender), stakes[msg.sender]);

        _reward(stakes[msg.sender]);

    */
    function withdraw(uint256 value) external returns (uint256 amount) {
        require(stakes[msg.sender] >= value, "INSUFFICIENT_STAKE");

        amount = stakes[msg.sender]
            .safe(SafeArithmetics.Operation.MUL, balance())
            .safe(SafeArithmetics.Operation.DIV, totalStakes);

        stakes[msg.sender] = stakes[msg.sender].safe(
            SafeArithmetics.Operation.SUB,
            value
        );

        totalStakes = totalStakes.safe(SafeArithmetics.Operation.SUB, value);

        _unlock(amount);
        _reward(value);
    }

    // Linear time based rewards
    function _reward(uint256 stake) internal {
        uint256 reward = stake * (block.timestamp - times[msg.sender]);

        if (reward > omni.balanceOf(address(this)))
            reward = omni.balanceOf(address(this));

        if (reward != 0) omni.transfer(msg.sender, reward);

        times[msg.sender] = 0;
    }

    modifier refund(uint256 value) {
        _;

        // Refund any excess ether sent to the contract
        if (msg.value > value)
            _send(
                payable(msg.sender),
                msg.value.safe(SafeArithmetics.Operation.SUB, value)
            );
    }
}
