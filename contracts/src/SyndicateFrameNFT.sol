// SPDX-License-Identifier: MIT
// By Will Papper
// Example NFT contract for the Syndicate Frame API
// Modified by EpicDylan for Deploy on Degen Week
// Page Open Source Project

pragma solidity ^0.8.20;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721//ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// $DEGEN token contract address
address constant DEGEN_TOKEN_ADDRESS = 0x888F05D02ea7B42f32f103C089c1750170830642;

contract SyndicateFrameNFT is ERC721, Ownable {
    uint256 public currentTokenId = 0;
    string public defaultURI;

    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => bool) public lockedTokenURIs;

    // Keep track of mint limits
    uint256 public maxMintPerAddress;
    mapping(address => uint256) public mintCount;

    event DefaultTokenURISet(string tokenURI);
    event TokenURISet(uint256 indexed tokenId, string tokenURI);
    event TokenURILocked(uint256 indexed tokenId);

    modifier onlyUnlockedTokenURI(uint256 tokenId) {
        require(!lockedTokenURIs[tokenId], "FrameNFTs: Token URI is locked");
        _;
    }

    modifier onlyBelowMaxMint(address to) {
        require(
            mintCount[to] < maxMintPerAddress,
            "FrameNFTs: Max mint reached"
        );
        _;
    }

    uint256 public collectedDEGEN;

    constructor() ERC721("PageDAO Ticket NFT", "TICK1") Ownable(msg.sender) {
        defaultURI = "https://ipfs.io/ipfs/QmWKBk8YzBgkH1nhbaiXba3JuWTJDukZTPDiZWx7RJZ1u7";
        maxMintPerAddress = 1;
    }

    function mint(address to) public {
        // Charge 100 $DEGEN tokens for the mint
        require(
            IERC20(DEGEN_TOKEN_ADDRESS).transferFrom(
                msg.sender,
                address(this),
                100 * 10**18
            ),
            "Failed to transfer $DEGEN"
        );

        ++currentTokenId;
        ++mintCount[to];
        _mint(to, currentTokenId);

        // Update the collected $DEGEN amount
        collectedDEGEN += 100 * 10**18;
    }

    function mint(address to, string memory _tokenURI)
        public
        onlyBelowMaxMint(to)
    {
        ++currentTokenId;
        ++mintCount[to];
        tokenURIs[currentTokenId] = _tokenURI;
        _mint(to, currentTokenId);

        emit TokenURISet(currentTokenId, _tokenURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyUnlockedTokenURI(tokenId)
    {
        tokenURIs[tokenId] = _tokenURI;

        emit TokenURISet(tokenId, _tokenURI);
    }

    function lockTokenURI(uint256 tokenId) public onlyOwner {
        lockedTokenURIs[tokenId] = true;

        emit TokenURILocked(tokenId);
    }

    function setDefaultTokenURI(string memory _tokenURI) public onlyOwner {
        defaultURI = _tokenURI;
        emit DefaultTokenURISet(_tokenURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        if (bytes(tokenURIs[tokenId]).length > 0) {
            return tokenURIs[tokenId];
        } else {
            return defaultURI;
        }
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) public onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function withdrawDEGEN(uint256 amount) public onlyOwner {
        require(amount <= collectedDEGEN, "Insufficient $DEGEN balance");
        require(
            IERC20(DEGEN_TOKEN_ADDRESS).transfer(msg.sender, amount),
            "Failed to transfer $DEGEN"
        );
        collectedDEGEN -= amount;
    }

    receive() external payable {
        revert("Does not accept ETH");
    }

    fallback() external payable {
        revert("Does not accept ETH");
    }
}
