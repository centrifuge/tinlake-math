// Copyright (C) 2018 Rain <rainbreak@riseup.net> and Centrifuge, referencing MakerDAO dss => https://github.com/makerdao/dss/blob/master/src/pot.sol
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

import "./math.sol";

contract Interest is Math {
    // @notice This function provides compounding in seconds
    // @param chi Accumulated interest rate over time
    // @param speed Interest rate accumulation per second in RAD(10ˆ27)
    // @param rho When the interest rate was last updated
    // @param pie Total sum of all amounts accumulating under one interest rate, divided by that rate
    // @return The new accumulated rate, as well as the difference between the debt calculated with the old and new accumulated rates.
    // TODO: rename this function
    function compounding(uint chi, uint speed, uint rho, uint pie) public view returns (uint, uint) {
        require(now >= rho, "tinlake-math/invalid-timestamp");
        require(chi != 0);
        uint updatedChi = chargeInterest(chi ,speed, rho);
        uint chi_ = safeSub(updatedChi, chi);
        return (updatedChi, rmul(pie, chi_));
    }

    // @notice This function updates chi
    // @param chi Accumulated interest rate over time
    // @param speed Interest rate accumulation per second in RAD(10ˆ27)
    // @param rho When the interest rate was last updated
    // @return The new accumulated rate
    function chargeInterest(uint bearingAmount, uint speed, uint rho) public view returns (uint) {
        if (now >= rho) {
            bearingAmount = rmul(rpow(speed, now - rho, ONE), bearingAmount);
        }
        return bearingAmount;
    }

    // convert pie to debt/savings amount
    function toAmount(uint chi, uint pie) public pure returns (uint) {
        return rmul(pie, chi);
    }

    // convert debt/savings amount to pie
    function toPie(uint chi, uint amount) public pure returns (uint) {
        return rdivup(amount, chi);
    }

    function rpow(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }
}