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

        // Transfer fee to the NFT owner and return the rest of the collateral to the borrower
        uint256 fee = calculateFee(borrowTimestamp, collateralAmount);
        uint256 remaining = collateralAmount - fee;
        address NFTOwner = NFTOwners[nftContract][tokenId];
        payable(NFTOwner).transfer(fee);
        payable(msg.sender).transfer(remaining);

        emit NFTReturned(msg.sender, nftContract, tokenId);
    }

    function calculateFee(uint256 borrowTimestamp, uint256 collateralAmount) internal view returns (uint256) {
        // Calculate fee based on borrowing duration
        uint256 duration = block.timestamp - borrowTimestamp;
        uint256 feeRate = 1; // 1% per hour
        uint256 fee = (collateralAmount * feeRate * duration) / (1 hours * 100);

        return fee;
    }
}