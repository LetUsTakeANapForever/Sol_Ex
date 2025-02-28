// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// Decimal to hexadecimal in bytes32 system

contract Convert {

    function convert(uint256 n) public  pure returns (bytes32) {
        return bytes32(n); // 1 byte = 15 hexdigits, or you can also type hexadecimal number 0x
    }

    function getHash(bytes32 data) public pure returns(bytes32){
        return keccak256(abi.encodePacked(data)); 
    }

    function getAddress() public view returns (address) {
        return address(this);
    }
}
