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

import "./math.sol";

contract Interest {
    // compounding takes in chi (accumulated rate), speed (accumulation per second), rho (when the rate was last updated),
    // and pie (total debt of all loans with one rate divided by that rate).
    // Returns the new accumulated rate, as well as the difference between the debt calculated with the old and new accumulated rates.
    function compounding(uint chi, uint speed, uint48 rho, uint pie) public view returns (uint chi_, uint delta) {
        // compounding in seconds
        require(chi != 0);
        uint debt = fromPie(chi, pie);
        uint chi_ = rmul(rpow(speed, now - rho, ONE), chi);
        delta = fromPie(chi_, pie) - debt;
        return (chi_, delta);
    }

    // convert pie to debt amount
    function fromPie(uint chi, uint pie) public pure returns (uint) {
        return rmul(pie, chi);
    }

    // convert debt amount to pie
    function toPie(uint chi, uint debt) public pure returns (uint) {
        return rdiv(debt, chi);
    }
}