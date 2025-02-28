
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TimeUnit.sol";
import "./Convert.sol";
import "./CommitReveal.sol";

contract RPS {
    
    uint public numPlayer = 0; // set player as 0 bc anyone can play
    uint public reward = 0;
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - Spock, 4 - Lizard
    mapping(address => bool) public player_not_played; // address is a player mapped to bool (playing or not playing).
    address[] public players; // account is like a public key and there must be a private key to open the private key.
    //and there's a smart contract owner who controls transac. sending.

    uint public numInput = 0;

    // P.S. addPlayer and input fns interlock

    TimeUnit public timeUnit = new TimeUnit();
    Convert public convert = new Convert();
    CommitReveal public  commitReveal = new CommitReveal();

    mapping(address => bool) public hasRevealedStatus;
    mapping(address => bytes32) public revealedHashed; // mapping add. with hashed data that belongs to each player
    uint public numInputToReveal = 0;
    mapping(address => uint256) public  randomNum; // mapping uint256 with randomNum of each player

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
        
        // if players pass criteria and are added, we set starttime
        timeUnit.setStartTime();

        // if we get 2 players we need to set start time again to check if no one plays we'll force endgaem.
        if (numPlayer == 2) {
            timeUnit.setStartTime();
            forcedEndGame();
        }else if (numPlayer == 1){
            checkIfRefund();
        }
    }

    function checkIfRefund() payable public{
        if (timeUnit.elapsedSeconds() > 3600){
            // refund player 0
            payable(players[0]).transfer(1 ether);
            numInput = numPlayer = reward = 0;
        }
    }

    // call input when we start playing
    function inputHash(bytes32 hashedChoice) public  {

        require(numPlayer == 2); // check if numPlayer == 2 yet, it not, we won't let you pass through this require line.
        require(player_not_played[msg.sender]); // check in the player_not_played ampping if this address (msg.sender) is true, if not you won't get through this line.
        // and a player who gives mapped true is the only one who calls addPlayer function before.
        // require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);
        

        //commit the hashedChoice here
        commitReveal.commit(hashedChoice);
        

        // player_choice[msg.sender] = choice; // set a new mapping called player_choice where each address is mapped with choice they choose.
        player_not_played[msg.sender] = false; // reset the state for the next round
        numInput++;


        //set starttime again here
        timeUnit.setStartTime();
    }

    //logic to check if elapsedSeconds > 3600, the owner will take action to force endgame
    function forcedEndGame() public {
        if (timeUnit.elapsedSeconds() > 3600){
            numInput = numPlayer = reward = 0;
        }
    }

    function inputHexToReveal(uint256 random_num, bytes32 hexInput) public{
        revealedHashed[msg.sender] = hexInput;
        randomNum[msg.sender] = random_num;
        numInputToReveal++;

        // TODO : a player must call reveal
        commitReveal.reveal(revealedHashed[msg.sender]);
        hasRevealedStatus[msg.sender] = true; 

        if (numInput == 2 && numInputToReveal == 2) { // check if both players have picked their choices.
            _checkWinnerAndPay();
        }
    }

    function getChoice(address player) public view returns (uint){
        uint256 random_num_xor_choice = uint256(revealedHashed[player]); // type cast from bytes32 to uint256
        uint choice = random_num_xor_choice^randomNum[player];
        return choice;
    }

    // private fn where others outside can't call, only ones in contract can call this fn.
    function _checkWinnerAndPay() private {
        // TODO : logic to check that all reveals are successful.
        require(hasRevealedStatus[players[0]] && hasRevealedStatus[players[1]]);

        // TODO : retrieve player0_choice from input to reveal
        uint p0Choice = getChoice(players[0]);

        // TODO : retrieve player1_choice from input to reveal
        uint p1Choice = getChoice(players[1]);

        address payable account0 = payable(players[0]); // type cast the variable player to be payable address to recieve ETH.
        address payable account1 = payable(players[1]);
        uint winner = getWinner(p0Choice, p1Choice);

        if (winner == 0) {
        account0.transfer(reward);
        } else if (winner == 1) {
            account1.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        numInput = numPlayer = reward = 0;
        }

    function getWinner(uint p0Choice, uint p1Choice) private pure returns (uint) {
        if (p0Choice == p1Choice) return 2; // draw

        // all winning cases for player 0
        if ((p0Choice == 0 && (p1Choice == 2 || p1Choice == 4)) || // Rock beats Scissors, Lizard
            (p0Choice == 1 && (p1Choice == 0 || p1Choice == 3)) || // Paper beats Rock, Spock
            (p0Choice == 2 && (p1Choice == 1 || p1Choice == 4)) || // Scissors beats Paper, Lizard
            (p0Choice == 3 && (p1Choice == 0 || p1Choice == 2)) || // Spock beats Rock, Scissors
            (p0Choice == 4 && (p1Choice == 1 || p1Choice == 3))) { // Lizard beats Paper, Spock
            return 0; // player 0 Wins
        }
        return 1; // player 1 Wins
    }

}

// Contracts should be as short as possible to save gas.

