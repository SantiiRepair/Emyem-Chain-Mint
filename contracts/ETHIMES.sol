// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract ETHIMES is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 40 ether; // 40 MATIC
    uint256 public maxSupply = 3333;
    uint256 public maxMintAmount = 100;
    uint256 public nftPerAddressLimit = 30;
    bool public paused = true; 
    bool public onlyWhitelisted = true;
    address payable public payments;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public addressMintedBalance;
    address[] public whitelistedAddresses = [
        0x58713D4f2c3356599B935Da0FA3B7C607C2CbCBc,
        0xFeD348B77932d7F26c8ccA590496C970D2b37599,
        0x43e750CD89d9FC79Ec664468BDA0BedaF852f527,
        0x0f71D09754a9773B27C6cdE79248F08BBB510ea2,
        0x24e681d3E9F834768613ec7D8c6C81310093Bf0C,
        0x2B93569DE1C9b857c326Cc11Ed505344422B1213,
        0xB5dFe3dd67F6B3d06a260ca8A8e37e82E4A63552,
        0xb6Dd6984aF9A04f63fF668b20bc147c897523Da5,
        0x3b40B6B1E1a815405fD7C939B35EBb4456f73c88,
        0x62b71A099E89F1D850044cf83b222cc43e570fC6,
        0xfA0823CE51c5B479ea0AADEe08c48A91FE929769,
        0x2DF5253F32CAC9626B70B70B0bD689F432B40133,
        0x81E377017494A66C0c6da0db79435334bB66bd09,
        0x758b6c6FC563A7934C4CA7078d64A6E4b3aEeAF2,
        0x9eFd21CbB01552e3445e1BE8c79C1e91A3724a24,
        0xbC07E5E9bF9E49FfB150912718Eaf6Ff7b4Ed8d0,
        0x4a35e3b8bA0592be8E60F59672e6eFD514b99570
    ];

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _payments 
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        payments = payable(_payments);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(!paused, "The contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "Max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "Max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "User is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                    "Max NFT per address exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount, "Insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
 
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    } 

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(payments).call{value: address(this).balance}("");
        require(success);
    }
}
