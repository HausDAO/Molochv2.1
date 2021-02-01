/*
██████╗ ██╗ ██████╗ █████╗ ██████╗ ██████╗ ██╗ █████╗ ███╗   ██╗
██╔══██╗██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗████╗  ██║
██████╔╝██║██║     ███████║██████╔╝██║  ██║██║███████║██╔██╗ ██║
██╔══██╗██║██║     ██╔══██║██╔══██╗██║  ██║██║██╔══██║██║╚██╗██║
██║  ██║██║╚██████╗██║  ██║██║  ██║██████╔╝██║██║  ██║██║ ╚████║
╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
██╗     ██╗      ██████╗                                        
██║     ██║     ██╔════╝                                        
██║     ██║     ██║                                             
██║     ██║     ██║                                             
███████╗███████╗╚██████╗                                        
╚══════╝╚══════╝ ╚═════╝*/
/// Presented by LexDAO LLC
/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.1;

contract RicardianLLC {
    address public governance;
    uint256 public mintFee;
    uint256 public totalSupply;
    string public masterOperatingAgreement;
    string constant public name = "Ricardian LLC, Series";
    string constant public symbol = "LLC";
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public salePrice;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed approver, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event GovTribute(address indexed caller, uint256 amount, string details);
    event GovUpdateSettings(address indexed governance, uint256 indexed mintFee, string masterOperatingAgreement);
    event GovUpdateTokenURI(uint256 indexed tokenId, string tokenURI);
    event UpdateSale(uint256 price, uint256 indexed tokenId);
    
    constructor(address _governance, string memory _masterOperatingAgreement) {
        governance = _governance; 
        masterOperatingAgreement = _masterOperatingAgreement; 
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
    }
    
    /*****************
    INTERNAL FUNCTIONS
    *****************/
    function _transfer(address from, address to, uint256 tokenId) private {
        require(from == ownerOf[tokenId], "!owner");
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0); // reset approval
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 
    }
    
    /*************
    PUBLIC MINTING
    *************/
    receive() external payable {
        require(msg.value == mintFee, "!mintFee"); // call with ETH fee
        totalSupply++;
        uint256 tokenId = totalSupply;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenURI[tokenId] = "";
        emit Transfer(address(0), msg.sender, tokenId); 
    }
    
    function mintLLC(address to) external payable returns (uint256 series) { 
        require(msg.value == mintFee, "!mintFee"); // call with ETH fee
        totalSupply++;
        uint256 tokenId = totalSupply;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        tokenURI[tokenId] = "";
        emit Transfer(address(0), to, tokenId); 
        return tokenId;
    }
    
    function mintLLCbatch(address[] calldata to) external payable {
        require(msg.value == mintFee * to.length, "!mintFee"); // call with ETH fee adjusted for batch
        for (uint256 i = 0; i < to.length; i++) {
            totalSupply++;
            uint256 tokenId = totalSupply;
            balanceOf[to[i]]++;
            ownerOf[tokenId] = to[i];
            tokenURI[tokenId] = "";
            emit Transfer(address(0), to[i], tokenId); 
        }
    }
    
    /******************
    PUBLIC BALANCE MGMT
    ******************/
    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        balanceOf[msg.sender]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0); // reset approval
        ownerOf[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId); 
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata tokenId) external {
        require(to.length == tokenId.length, "!to/tokenId");
        for (uint256 i = 0; i < to.length; i++) {
            require(msg.sender == ownerOf[tokenId[i]], "!owner");
            balanceOf[msg.sender]--; 
            balanceOf[to[i]]++; 
            getApproved[tokenId[i]] = address(0); // reset approval
            ownerOf[tokenId[i]] = to[i];
            emit Transfer(msg.sender, to[i], tokenId[i]); 
        }
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        require(from == owner, "!owner");
        require(msg.sender == owner || getApproved[tokenId] == msg.sender || isApprovedForAll[owner][msg.sender], "!owner/spender/operator");
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0); // reset approval
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 
    }
    
    // ***********
    // PUBLIC SALE
    // ***********
    function purchase(uint256 tokenId) external payable {
        uint256 price = salePrice[tokenId];
        require(price > 0, "!forSale");
        require(msg.value == price, "!price");
        address owner = ownerOf[tokenId];
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "!ethCall");
        balanceOf[owner]--; 
        balanceOf[msg.sender]++; 
        getApproved[tokenId] = address(0); // reset approval
        ownerOf[tokenId] = msg.sender;
        emit Transfer(owner, msg.sender, tokenId); 
    }
    
    function updateSale(uint256 price, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        salePrice[tokenId] = price;
        emit UpdateSale(price, tokenId);
    }

    /*******************
    GOVERNANCE FUNCTIONS
    *******************/
    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }
    
    function govMintLLC(address to) external onlyGovernance returns (uint256 series) { 
        totalSupply++;
        uint256 tokenId = totalSupply;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        tokenURI[tokenId] = "";
        emit Transfer(address(0), to, tokenId); 
        return tokenId;
    }
    
    function govMintLLCbatch(address[] calldata to) external onlyGovernance {
        for (uint256 i = 0; i < to.length; i++) {
            totalSupply++;
            uint256 tokenId = totalSupply;
            balanceOf[to[i]]++;
            ownerOf[tokenId] = to[i];
            tokenURI[tokenId] = "";
            emit Transfer(address(0), to[i], tokenId); 
        }
    }
    
    function govTransferFrom(address from, address to, uint256 tokenId) external onlyGovernance {
        require(from == ownerOf[tokenId], "!owner");
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0); // reset approval
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 
    }
    
    function govTransferFromBatch(address[] calldata from, address[] calldata to, uint256[] calldata tokenId) external {
        require(from.length == to.length && to.length == tokenId.length, "!from/to/tokenId");
        for (uint256 i = 0; i < from.length; i++) {
            require(from[i] == ownerOf[tokenId[i]], "!owner");
            balanceOf[from[i]]--; 
            balanceOf[to[i]]++; 
            getApproved[tokenId[i]] = address(0); // reset approval
            ownerOf[tokenId[i]] = to[i];
            emit Transfer(from[i], to[i], tokenId[i]); 
        }
    }
    
    function govTribute(string calldata details) external payable {
        (bool success, ) = governance.call{value: msg.value}("");
        require(success, "!ethCall");
        emit GovTribute(msg.sender, msg.value, details);
    }
    
    function govUpdateSettings(address _governance, uint256 _mintFee, string calldata _masterOperatingAgreement) external onlyGovernance {
        governance = _governance;
        mintFee = _mintFee;
        masterOperatingAgreement = _masterOperatingAgreement;
        emit GovUpdateSettings(_governance, _mintFee, _masterOperatingAgreement);
    }
    
    function govUpdateTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyGovernance {
        require(tokenId <= totalSupply, "!exist");
        tokenURI[tokenId] = _tokenURI;
        emit GovUpdateTokenURI(tokenId, _tokenURI);
    }
    
    function govUpdateTokenURIbatch(uint256[] calldata tokenId, string[] calldata _tokenURI) external onlyGovernance {
        require(tokenId.length == _tokenURI.length, "!tokenId/_tokenURI");
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(tokenId[i] <= totalSupply, "!exist");
            tokenURI[tokenId[i]] = _tokenURI[i];
            emit GovUpdateTokenURI(tokenId[i], _tokenURI[i]);
        }
    }
}
