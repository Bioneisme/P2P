pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract StreamCore  {

    IERC20 streamToken;

    mapping(uint256 => ContentConsumer) public contentConsumers;
    // consumer ID || contentConsumers[consumerID] = { consumerAddr, name, twitterID } 
    mapping(uint256 => ContentCreator) public contentCreators;
    // creator ID ||  contentCreators[creatorID] = { creatorAddr, name, streamTimeLimit, currentlyStreaming, verifiedContentCreator, twitterID }
    mapping(uint256 => mapping(uint256 => Subscription)) public subscriptions;
    // subscription ID || subscriptions[creatorId][consumerId] = { contentCreator, contentConsumer, paymentAmount, streamTime }
    mapping(uint256 => Stream) public streams;
    // stream ID || streams[streamId] = { streamStartTime, streamEndTime, streamTimeRemaining, streamStatus, streamRecipient, streamers }

    mapping(address => ContentConsumer) public addrToConsumer;
    
    mapping(address => ContentCreator) public addrToCreator;

    uint256 public nextConsumerID;
    uint256 public nextCreatorID;
    uint256 public nextStreamID;

    constructor(address _token) {
        streamToken = IERC20(_token);
    }

    struct ContentCreator {
        address addr;
        string name;
        uint creatorId;
        bool currentlyStreaming;
        bool verifiedContentCreator;
        string twitterID;
    }

    struct ContentConsumer {
        address addr;
        string name;
        string twitterID;
        uint consumerId;
    }

    struct Subscription {
        ContentCreator contentCreator;
        ContentConsumer contentConsumer;
        uint paymentAmount;
        uint streamTime;
    }

    struct Stream {
        uint streamStartTime;
        uint streamEndTime;
        uint streamTimeRemaining;
        address[] streamers;
        address streamRecipient;
    }


    function registerAsContentCreator(string memory _name, string memory _twitterID) external {
        uint creatorId = nextCreatorID;
        nextCreatorID++;
        contentCreators[creatorId] = ContentCreator({
            addr: msg.sender,
            name: _name,
            creatorId: creatorId,
            currentlyStreaming: false,
            verifiedContentCreator: false,
            twitterID: _twitterID
        });
    }

    function registerAsConsumer(string memory _name, string memory _twitterID) external {
        uint consumerID = nextConsumerID;
        nextConsumerID++;
        contentConsumers[consumerID] = ContentConsumer({
            addr: msg.sender,
            name: _name,
            twitterID: _twitterID,
            consumerId: consumerID
        });
    }

    function createSubscription(uint256 _creatorID, uint256 _consumerID, uint _paymentAmount, uint _streamTime) external {
        ContentCreator storage contentCreator = contentCreators[_creatorID];
        ContentConsumer storage contentConsumer = contentConsumers[_consumerID];

        Subscription memory newSubscription = Subscription({
            contentCreator: contentCreator,
            contentConsumer: contentConsumer,
            paymentAmount: _paymentAmount,
            streamTime: _streamTime
        });

        subscriptions[_creatorID][_consumerID] = newSubscription;
    }

    function createStream(uint _creatorId) external {
        Stream memory newStream = Stream({
            streamStartTime: block.timestamp,
            streamEndTime: block.timestamp + 90 minutes,
            streamTimeRemaining: 90 minutes,
            streamers: new address[](0),
            streamRecipient: contentCreators[_creatorId].addr
        });

        contentCreators[_creatorId].currentlyStreaming = true;
        streams[nextStreamID] = newStream;
        nextStreamID++;
    }

    function endStream(uint _streamId, uint _creatorId) external {
        contentCreators[_creatorId].currentlyStreaming = false;
        streams[_streamId].streamTimeRemaining = 0;
    }

    function joinStream(uint _streamId, uint _consumerId) external {
        Stream memory stream = streams[_streamId];
        require(stream.streamTimeRemaining > 0, "Stream has already ended");

        ContentConsumer storage contentConsumer = contentConsumers[_consumerId];
        address consumerAddress = contentConsumer.addr;

        uint streamStart = streams[_streamId].streamStartTime;
        uint streamEnd = streams[_streamId].streamEndTime;
        if(streamEnd == 0 || streamEnd > block.timestamp) {
            // stream has no end or still running
            stream.streamTimeRemaining = streamEnd - block.timestamp;
            address[] memory streamers = stream.streamers;
            streamers.push(consumerAddress);
            streams[_streamId].streamers = streamers;

        }
        
        
    }

}