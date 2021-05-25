// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15;

import "ds-test/test.sol";

import "../interest.sol";

interface Hevm {
    function warp(uint256) external;
}

contract InterestTest is Interest, DSTest{

    Hevm hevm;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1234567);
    }

    function testUpdateChiSec() public  {
        /*
        Compound period in pile is in seconds
        compound seconds = (1+r/n)^nt

        rate = (1+(r/n))*10^27 (27 digits precise)

        Example:
        given a 1.05 interest per day (seconds per day 3600 * 24)

        r = 0.05
        i = (1+r/(3600*24))^(3600*24) would result in i = 1.051271065957324097526787272

        rate = (1+(0.05/(3600*24)))*10^27
        rate = 1000000593415115246806684338
        */
        uint rate = 1000000593415115246806684338; // 5 % per day compound in seconds
        uint cache = block.timestamp;
        uint chi = chargeInterest(ONE, rate, block.timestamp);
        // one day later
        hevm.warp(block.timestamp + 1 days);
        uint chi_ = chargeInterest(chi, rate, cache);
        assertEq(chi_,1052608164847005065391965708);
    }

    function testUpdateChiDay() public  {
        /*
        Compound period in pile is in seconds
        compound seconds = (1+r/n)^nt

        rate = (1+(r/n))*10^27 (27 digits precise)

        Example: compound in seconds should result in 1.05 interest per day

        given i = 1.05
        solve equation for r
        i = (1+r/n)^nt
        r = n * (i^(1/n)-1

        use calculated r for rate equation
        rate = (1+((n * (i^(1/n)-1)/n))*10^27

        simplified
        rate = i^(1/n) * 10^27

        rate = 1.05^(1/(3600*24)) * 10^27 // round 27 digit
        rate = 1000000564701133626865910626

        */
        uint rate = 1000000564701133626865910626; // 5 % day
        uint cache = block.timestamp;
        uint chi = chargeInterest(ONE, rate, block.timestamp);
        assertEq(chi, ONE);
        // one day later
        hevm.warp(block.timestamp + 2 days);
        // new chi should = 1,05**2
        uint chi_ = chargeInterest(chi, rate, cache);
        assertEq(chi_, 1102500000000000000000033678);
    }

    function testCompounding() public  {
        uint rate = 1000000564701133626865910626; // 5 % day
        uint cache = block.timestamp;
        uint pie = toPie(ONE, 100 ether);
        (uint chi, uint delta) = compounding(ONE, rate, block.timestamp, pie);
        assertEq(delta, 0);

        // one day later
        hevm.warp(block.timestamp + 1 days);
        (uint updatedChi,uint delta_) = compounding(chi, rate, cache, pie);
        uint newAmount = toAmount(pie, updatedChi);
        uint oldAmount = toAmount(pie, chi);
        assertEq(delta_, 5000000000000000000);
        assertEq(newAmount - oldAmount, delta_);
    }


    function testCompoundingDeltaAmount() public {
        uint amount = 10 ether;
        uint chi = 1000000564701133626865910626; // 5% day
        uint pie = toPie(chi, amount);

        // random chi increase
        uint last = now;
        hevm.warp(now + 3 days + 123 seconds);
        (uint latestChi, uint deltaAmount) = compounding(chi, chi, last ,pie);

        assertEq(toAmount(latestChi, pie) -  toAmount(chi, pie), deltaAmount);
    }

    function testChargeInterest() public {
        uint amount = 100 ether;
        uint lastUpdated = now;

        uint ratePerSecond = 1000000564701133626865910626; // 5 % day
        hevm.warp(now + 1 days);
        uint updatedAmount = chargeInterest(amount, ratePerSecond, lastUpdated);
        assertEq(updatedAmount, 105 ether);
    }
}
