pragma solidity ^0.8.0;

import {ERC20} from '@solmate/tokens/ERC20.sol';

contract StreamToken is ERC20 {
    constructor() ERC20("StreamToken", "STK", 18) {
        _mint(msg.sender, 100_000_000 ether);
    }

    struct ContentCreator {
        address addr;
        string name;
        uint streamTimeLimit;
        bool currentlyStreaming;
        bool verifiedContentCreator;
        string twitterID;
    }

    struct ContentConsumer {
        address contentConsumerAddress;
        string name;
        string twitterID;
    }


}