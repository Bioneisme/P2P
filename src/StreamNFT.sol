pragma solidity ^0.8.0;

import {ERC721} from "@solmate/tokens/ERC721.sol";

contract StreamNFT is ERC721 {
    constructor() ERC721("StreamNFT", "SNFT") {}

    mapping(uint256 => string) private _dataUri;

    struct Viewership {
        uint256 viewStartTime;
        uint256 streamStartTime;
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
        uint streamId;
        uint streamStartTime;
        uint streamEndTime;
        uint streamTimeRemaining;
        address[] streamers;
        address streamRecipient;
    }

    struct Token {
        uint256 tokenId;
        string metadata;
    }

    mapping(uint256 => Stream) public tokenToStream;
    // Stream of the associated tokenId;


    /// @dev To make a new NFT that can be minted; The creator would call this for example
    /// @param _addr This is the stream recipient address, generally the creator
    /// @param _start The timestamp at which a stream begins
    /// @param _end This is the timestamp at the end of the stream
    /// @param _id This is the ID of the stream
    /// @notice Creates the Stream object in the mapping, then stores the struct in the mapping
    function createStreamNFT(address _addr, uint256 _start, uint256 _end, uint256 _id) external {
        tokenToStream[_id] = Stream(_id, _start, _end, _start - _end, address[](0), _addr);
    }

    /// @dev To Mint a new Token
    /// @param _addr This is the address of the user who will own the minted NFT
    /// @param _id This is the ID of the stream that the NFT should point to
    /// @notice This adds a streamer address to the array of streamers and mints them an nft 
    function mintStreamNFT(address _addr, uint256 _id) external {
        Stream memory stream = tokenToStream[_id];
        Viewership memory viewership = Viewership(block.timestamp, stream.streamStartTime);

        tokenToStream[_id].streamers.push(_addr);
        _safeMint(_addr, _id);
        setDataUri(_id, stream);
    }

    /// @dev Just a super basic getter for the stream mapping
    /// @param _id So we can get a specific stream
    /// @notice This returns the entire Stream object
    function getStream(uint256 _id) public view returns (Stream memory) {
        return tokenToStream[_id];
    }

    /// @dev Sets the DataUri for the Stream NFT
    /// @param _id The specific stream we want to include in the dataURI
    /// @param _stream The actual stream associated with this token
    // @todo update the uri each time the stream is joined by a viewer.
    function setDataUri(uint256 _id, Stream calldata _stream) public {
        _dataUri[_id] = tokenURI(Viewership(_stream.viewStartTime, _stream.streamStartTime));
    }

    /// @dev Just a super basic getter
    /// @param _id So we can get a specific token uri
    /// @notice This simply returns the specific data uri associated with the stream token id

    function getStreamDataUri(uint256 _id) public view returns (string memory) {
        return _dataUri[_id];
    }

    /// @dev To keep track of viewship, using abi.encodePacked to form a JSON like object in a string
    /// @param _viewership Struct containing the start times
    /// @notice This creates a custom data uri that is stored in the _dataUri mapping
    // @todo update the uri each time the stream is joined by a viewer.
    function tokenURI(Viewership calldata _viewership)
        public
        pure
        returns (string memory)
    {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"viewStartTime": "',
            _viewership.viewStartTime,
            '",',
            '"streamStartTime": "',
            _viewership.streamStartTime,
            '"',
            "}"
        );
    }

    /// @dev Override of safeMint from ERC721
    /// @param _to Address of the owner
    /// @param id The ID we're minting
    /// @notice Overrides the safeMint from the ERC721 parent
    // @todo update viewership and others on each mint
    function _safeMint(address _to, uint256 id) internal override {
        super._safeMint(_to, id);
    }









    function ownerOf(uint256 id) public view override returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

        function approve(address spender, uint256 id) public override {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                StreamNFT(to).onERC721Received(msg.sender, from, id, "") ==
                StreamNFT.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                StreamNFT(to).onERC721Received(msg.sender, from, id, data) ==
                StreamNFT.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

    }

        function _mint(address to, uint256 id) internal override {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal override {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal override {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal override {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return StreamNFT.onERC721Received.selector;
    }
}
