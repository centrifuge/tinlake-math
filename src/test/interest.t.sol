// Copyright (C) 2018 Centrifuge
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

import "ds-test/test.sol";

import "../interest.sol";

contract Hevm {
    function warp(uint256) public;
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
        uint cache = now;
        uint chi = chargeInterest(ONE, rate, now);
        // one day later
        hevm.warp(now + 1 days);
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
        uint cache = now;
        uint chi = chargeInterest(ONE, rate, now);
        assertEq(chi, ONE);
        // one day later
        hevm.warp(now + 2 days);
        // new chi should = 1,05**2
        uint chi_ = chargeInterest(chi, rate, cache);
        assertEq(chi_, 1102500000000000000000033678);
    }

    function testCompounding() public  {
        uint rate = 1000000564701133626865910626; // 5 % day
        uint cache = now;
        uint pie = toPie(ONE, 100 ether);
        (uint chi, uint delta) = compounding(ONE, rate, now, pie);
        assertEq(delta, 0);

        // one day later
        hevm.warp(now + 1 days);
        (uint updatedChi,uint delta_) = compounding(chi, rate, cache, pie);
        uint newAmount = toAmount(pie, updatedChi);
        uint oldAmount = toAmount(pie, chi);
        assertEq(delta_, 5000000000000000000);
        assertEq(newAmount - oldAmount, delta_);
    }
}