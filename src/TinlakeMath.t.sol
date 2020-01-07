pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./TinlakeMath.sol";

contract TinlakeMathTest is DSTest {
    TinlakeMath math;

    function setUp() public {
        math = new TinlakeMath();
    }
}
