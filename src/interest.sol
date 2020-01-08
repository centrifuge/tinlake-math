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
        uint latest = rmul(rpow(speed, now - rho, ONE), chi);
        uint chi_ = sub(latest, chi);
        return (latest, mul(pie, chi_));
    }

    // @notice This function updates chi
    // @param chi Accumulated interest rate over time
    // @param speed Interest rate accumulation per second in RAD(10ˆ27)
    // @param rho When the interest rate was last updated
    // @return The new accumulated rate
    function updateChi(uint chi, uint speed, uint rho) public view returns (uint) {
        if (now >= rho) {
        chi = rmul(rpow(speed, now - rho, ONE), chi);
        }
        return chi;
    }

    // convert pie to debt/savings amount
    function toAmount(uint chi, uint pie) public pure returns (uint) {
        return rmul(pie, chi);
    }

    // convert debt/savings amount to pie
    function toPie(uint chi, uint amount) public pure returns (uint) {
        return rdiv(amount, chi);
    }
}