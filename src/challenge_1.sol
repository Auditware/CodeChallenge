pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTStakingPlatform is ReentrancyGuard {
    mapping(address => mapping (uint256 => uint256)) public collateralAmounts;
    mapping(address => mapping (uint256 => address)) public NFTOwners;
    mapping(address => mapping (uint256 => uint256)) public borrowTimestamps;

    event NFTStaked(address indexed nftOwner, address nftContract, uint256 tokenId, uint256 collateralAmount);
    event NFTUnstaked(address indexed nftOwner, address nftContract, uint256 tokenId);
    event NFTBorrowed(address indexed borrower, address nftContract, uint256 tokenId);
    event NFTReturned(address indexed borrower, address nftContract, uint256 tokenId);
    event NFTLiquidated(address indexed nftOwner, address nftContract, uint256 tokenId);

    function stakeNFT(address nftContract, uint256 tokenId, uint256 collateralAmount) external nonReentrant {
        require(collateralAmount > 0, "CollateralAmount must be non-zero");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        NFTOwners[nftContract][tokenId] = msg.sender;
        collateralAmounts[nftContract][tokenId] = collateralAmount;

        emit NFTStaked(msg.sender, nftContract, tokenId, collateralAmount);
    }

    function unstakeNFT(address nftContract, uint256 tokenId) external nonReentrant {
        require(NFTOwners[nftContract][tokenId] == msg.sender, "You are not the owner of this NFT");
        require(borrowTimestamps[nftContract][tokenId] == 0, "NFT is currently borrowed");

        collateralAmounts[nftContract][tokenId] = 0;
        NFTOwners[nftContract][tokenId] = address(0);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit NFTUnstaked(msg.sender, nftContract, tokenId);
    }

    function borrowNFT(address nftContract, uint256 tokenId) external payable nonReentrant {
        uint256 collateralAmount = collateralAmounts[nftContract][tokenId];
        require(collateralAmount > 0, "No matching NFT staked");
        require(borrowTimestamps[nftContract][tokenId] == 0, "NFT is currently borrowed");
        require(msg.value == collateralAmount, "Incorrect collateral amount");

        borrowTimestamps[nftContract][tokenId] = block.timestamp;
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit NFTBorrowed(msg.sender, nftContract, tokenId);
    }

    function returnNFT(address nftContract, uint256 tokenId) external nonReentrant {
        uint256 collateralAmount = collateralAmounts[nftContract][tokenId];
        uint256 borrowTimestamp = borrowTimestamps[nftContract][tokenId];
        require(collateralAmount > 0, "No matching NFT staked");
        require(borrowTimestamp > 0, "NFT is not currently borrowed");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // Return the rest of the collateral to the borrower
        payable(msg.sender).transfer(collateralAmount);
        borrowTimestamps[nftContract][tokenId] = 0;

        emit NFTReturned(msg.sender, nftContract, tokenId);
    }

    function liquidateBorrowedNFT(address nftContract, uint256 tokenId) external nonReentrant {
        require(NFTOwners[nftContract][tokenId] == msg.sender, "You are not the owner of this NFT");
        require(borrowTimestamps[nftContract][tokenId] > 0, "NFT is not currently borrowed");
        uint256 duration = block.timestamp - borrowTimestamps[nftContract][tokenId];
        require(duration >= 100 hours, "Borrow duration has not elapsed, collateral remains");

        uint256 collateralAmount = collateralAmounts[nftContract][tokenId];
        collateralAmounts[nftContract][tokenId] = 0;
        NFTOwners[nftContract][tokenId] = address(0);
        borrowTimestamps[nftContract][tokenId] = 0;

        payable(msg.sender).transfer(collateralAmount);

        emit NFTLiquidated(msg.sender, nftContract, tokenId);
    }
}