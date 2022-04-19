//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract NFTMarket is ReentrancyGuard , ERC721URIStorage {
    using Counters for Counters.Counter;
    //Each individual market item thats created
    Counters.Counter private _itemIds;
    //Working with array, can't have dynamic length array : bought, created, not sold etc.
    Counters.Counter private _itemsSold;
    //Want to be able to determine who is the owner of the contract(charge a listing fee)
    address payable owner;
    uint256 listingPrice = 0.025 ether;
    //keep track and contiune incrementing tokenIds
    Counters.Counter private _tokenIds;


    constructor() ERC721("Culture Tokens", "CTT") { 
        owner = payable(msg.sender);
    } 
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //keep track of MarketItem by id 
    mapping(uint256 => MarketItem ) private idToMarketItem;

    //Event when marketItem is created, to be able to listen to events 
    event MarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    //function that can update listing price of contract
    function updateListingPrice(uint _listingPrice) public payable { 
        require(owner == msg.sender, "Only marketplace owner can update listing price");
        listingPrice = _listingPrice; 
    }

    //function that returns listing price
    function getListingPrice() public view returns(uint256) { 
        return listingPrice;
    }

     //for minting new tokens
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) { 
        //increment tokenIds
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        //mint token
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        createMarketItem(newItemId ,price);
        //get a hold up the token on the frontEnd Client
        return newItemId;
    }

    //allow someone to resell a token that they have purchased 
    function resellToken(uint256 tokenId, uint256 price) public payable { 
        require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }


    //function creates a marketItem and putting it for sale 
    function createMarketItem(uint256 tokenId, uint256 price ) public payable nonReentrant { 
        //Cost to list
        require(price > 0 , "Price must be least 1 wei");
        //require user sending in transaction, his payment is paying for the listing price
        require(msg.value == listingPrice, "Price must be equal to listing price");
        //increment ItemIDS
        _itemIds.increment();
        //var is the ID for marketplace Item going for sale
        uint256 itemId = _itemIds.current();
        //create the marketItem aswell create the mapping for the marketItem.
        idToMarketItem[itemId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)), //seller is putting it for sale || Nobody owns it at this moment.
            price,
            false
        );


    //tranfer NFT to buyer
    // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    //transfer 
    emit MarketItemCreated( tokenId, msg.sender, address(0), price, false);
    }

    //creating a market sale 
    function createMarketSale( uint256 itemId) public payable nonReentrant { 
        uint price = idToMarketItem[itemId].price;
        address seller = idToMarketItem[itemId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete purchase");
        
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        idToMarketItem[itemId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, itemId);
        payable(seller).transfer(msg.value); 

        //tranfer the ownership from the contract address to the buyer
        // IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        //updating mapping
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);


    }
    //function that returns an array of marketItmes
    function fetchMarketItems() public view returns (MarketItem[] memory) { 
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;
        
        //new arrary equal to the length of unsoldeItemCount
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for(uint i = 0; i < itemCount; i++) { 
            if(idToMarketItem[i + 1].owner == address(this)) { 
                uint currentId = i + 1; //id of item currently being interacted with.
                MarketItem storage currentItem = idToMarketItem[currentId]; //reference to market item we want to insert into array
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }

         }
        return items;
    }
    //function the NFTS that user has purchased
    function fethMyNFTS() public view returns(MarketItem [] memory) { 
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        //fetch the Items that YOU created for each individual user
        //loop over all the items
        for (uint i =0; i <totalItemCount; i++) { 
            if(idToMarketItem[i+1].owner == msg.sender) { 
                itemCount + 1;
            }
        }

        //Now you see how many you own/bough
        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint i = 0; i < totalItemCount; i++) { 
            if (idToMarketItem[i+1].owner == msg.sender) { 
                uint currentId = i +  1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex+=1;
            }
        }
        return items;

    }

    //Fetch NFTS that user has created himself
    function fetchItemsCreated() public view returns(MarketItem[] memory) { 
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount; i++) { 
            if(idToMarketItem[i+1].seller == msg.sender) { 
                itemCount + 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i <totalItemCount; i++) { 
            if(idToMarketItem[i+1].seller == msg.sender) { 
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }

        return items;

    }


}