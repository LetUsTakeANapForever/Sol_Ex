
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RPS {
    uint public numPlayer = 0; // set player as 0 bc anyone can play
    uint public reward = 0;
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors
    mapping(address => bool) public player_not_played; // address is a player mapped to bool (playing or not playing).
    address[] public players; // account is like a public key and there must be a private key to open the private key.
    //and there's a smart contract owner who controls transac. sending.

    uint public numInput = 0;

    // P.S. addPlayer and input fns interlock

    function addPlayer() public payable {
        require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 || msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 || msg.sender == 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db || msg.sender == 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        require(numPlayer < 2); // reqiure is like access in js. and only 2 people are allowed to play, therefore we can get through this line.
        //P.S. at one point we won't be able to call this function anymore.
        if (numPlayer > 0) {
            // if numPlayer > 0 aka. numPlayer == 1 means that there's a player added into the contract.
            require(msg.sender != players[0]); // to make sure that the player isn't the same account playing with their own account.
            // msg.sender is who calls smart contract function, so it'll be varied depending on who calls.
        }
        // deploy section interface set 1 ETH for each account that are playing.
        require(msg.value == 1 ether); // each player must have 1 ether to send to the middle warehouse. 
        reward += msg.value;
        player_not_played[msg.sender] = true; // mapping to the amount of boolean
        players.push(msg.sender); // add a player into the array whof passes all criteria
        numPlayer++;
    }

    // call input when we start playing
    function input(uint choice) public  {
        require(numPlayer == 2); // check if numPlayer == 2 yet, it not, we won't let you pass through this require line.
        require(player_not_played[msg.sender]); // check in the player_not_played ampping if this address (msg.sender) is true, if not you won't get through this line.
        // and a player who gives mapped true is the only one who calls addPlayer function before.
        require(choice == 0 || choice == 1 || choice == 2);
        player_choice[msg.sender] = choice; // set a new mapping called player_choice where each address is mapped with choice they choose.
        player_not_played[msg.sender] = false; // ? reset the state for the next round?
        numInput++;
        if (numInput == 2) { // check if both players have picked their choices.
            _checkWinnerAndPay();
        }
    }

    // private fn where others outside can't call, only ones in contract can call this fn.
    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]); // type cast the variable player to be payable address to recieve ETH.
        address payable account1 = payable(players[1]);
        if ((p0Choice + 1) % 3 == p1Choice) { // all of the possibilities that acc1 wins
            // to pay player[1] for 2 ETH
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 3 == p0Choice) { // all of the possibilities that acc0 wins
            // to pay player[0] for 2 ETH
            account0.transfer(reward);    
        }
        else { // in case, they're even.
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        numInput = numPlayer = reward = 0;

    }
}

// Contracts should be as short as possible to save gas.