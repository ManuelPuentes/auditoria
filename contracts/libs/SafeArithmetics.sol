// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeArithmetics {
    enum Operation {
        ADD,
        SUB,
        MUL,
        DIV,
        POW
    }

    function safe(uint256 a, Operation op) internal pure returns (uint256) {
        return safe(a, op, a);
    }

    /** 
        @notice mul operator have an error, they ommited  multiplication by zero case, if they try to multiplicate by zero they will get an error, after the number is multiplied they called div case and they sent 0 as b parameter this will generate an exception in a none error operation, they should added this case. 
        
        if( a || b == 0 ){

            returns 0
        }else{

            ... current code ...

        }  
            
        or they can used the openzeppelin safeMAth library:
        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

    */


    function safe(
        uint256 a,
        Operation op,
        uint256 b
    ) internal pure returns (uint256) {
        if (op == Operation.ADD) {
            a += b;
            require(a >= b);
        } else if (op == Operation.SUB) {
            a -= b;
            require(a <= b);
        } else if (op == Operation.MUL) {
            uint256 c = a;
            a *= b;
            require(safe(a, Operation.DIV, b) == c);
        } else if (op == Operation.DIV) {
            require(b != 0);
            a /= b;
        } else if (op == Operation.POW) {
            uint256 c = a;
            a**b;
            require(a >= c || a == 1);
        }

        return a;
    }
}
