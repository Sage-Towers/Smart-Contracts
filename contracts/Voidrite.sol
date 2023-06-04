// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Voidrite is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply, IERC1155Receiver, ReentrancyGuard {

    using Address for address payable;
    uint256 public constant VOIDRITE = 1;
    uint256 public constant VOIDTOUCHED = 2;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CLEANER_ROLE = keccak256("CLEANER_ROLE");
    mapping (uint256 => string) private _tokenURIs;
    string private ContractURI;
    uint256 public MaxSupply = 500000;
    uint256 public MaxMintsPerTx = 4999;
    uint256 public CurrentSupply;
    bool public MintingEnabled;
    uint256 public MintPrice;
    uint256 public SellPrice;
    uint256 public BuyPrice;
    uint256 public VoidritePool = 0;
    uint256 public CooldownTime = 1 days;
    uint256 public TotalStaked;
    struct StakerData {
        uint256 balance;
        uint256 lastStaked;
    }
    mapping(address => StakerData) private Stakers;
    event VoidriteHarvested(address indexed to, uint256 amount);
    event VoidCleanse(address indexed from, uint256 amount);
    event VoidBuy(address indexed to, uint256 amount);
    event VoidSell(address indexed from, uint256 amount);
    event VoidStake(address indexed who, uint256 amount);
    event VoidUnstake(address indexed who, uint256 amount);
    constructor() ERC1155("") {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(CLEANER_ROLE, msg.sender);
        MintingEnabled = false;
        MintPrice = 0.001337 ether;
        SellPrice = MintPrice * 96 / 100;
        BuyPrice =  MintPrice * 104 / 100;
        _tokenURIs[VOIDRITE] = "ipfs://QmPBLbSjhBvv5JgepMSrzvAX9yAXDn3k4hfmmkeGQSirsd";
        _tokenURIs[VOIDTOUCHED] = "ipfs://QmTYaVmrhzwXdQAdX8V8z77y9e3ePsGbLKYYKMc2wmkSCA";
        ContractURI= "ipfs://QmZhjTbeqohopYTL3dzoicyWeLTPFHWsoRxzGYU1azmMDH";
        _mint(msg.sender, VOIDRITE, 60000, "");
        _mint(msg.sender, VOIDTOUCHED, 60000, ""); 
        CurrentSupply+=60000;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Only admin can perform this action");
        _;
    }

    function addAddressToCleaner(address account) external onlyAdmin {
        _setupRole(CLEANER_ROLE, account);
    }

    function addAddressToAdmin(address account) external onlyAdmin {
        _setupRole(ADMIN_ROLE, account);
    }

    function setMaxSupply(uint256 supply) external onlyAdmin(){
        MaxSupply=supply;
    }

    function setMaxMintPerTx(uint256 maxTx) external onlyAdmin() {
        MaxMintsPerTx=maxTx;
    }

    function toggleMinting(bool enabled) external onlyAdmin() {
        MintingEnabled = enabled;
    }

    function setMintPrice(uint256 _mintPrice) external onlyAdmin() {
        MintPrice = _mintPrice;
    }

    function setSellPrice(uint256 _sellPrice) external onlyAdmin() {
        SellPrice = _sellPrice;
    }

    function setBuyPrice(uint256 _buyPrice) external onlyAdmin() {
        BuyPrice = _buyPrice;
    }
    
    function setCooldownStake(uint256 _time) external onlyAdmin() {
        CooldownTime = _time;
    }

    function setTokenURI(uint256 tokenId, string memory newURI) external onlyAdmin {
        _tokenURIs[tokenId] = newURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function setContractURI(string memory newURI) external onlyAdmin {
        ContractURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(MintingEnabled, "Minting is currently disabled");
        require((CurrentSupply+(amount)) <= MaxSupply, "Exceeds max supply");
        require(amount <= MaxMintsPerTx, "Exceeds max mints per transaction");
        require(msg.value >= (MintPrice*amount), "Ether value sent is not correct");
        _mint(msg.sender, VOIDRITE, amount, "");
        _mint(msg.sender, VOIDTOUCHED, amount, ""); 
        CurrentSupply+=amount;
        emit VoidriteHarvested(msg.sender, amount);
    }

    function stake(uint256 _amount) external {
        require(balanceOf(msg.sender, VOIDRITE) >= _amount, "You cannot stake more tokens than you hold");
        safeTransferFrom(msg.sender, address(this), 1, _amount, "");
        StakerData storage user = Stakers[msg.sender];
        user.balance += _amount;
        user.lastStaked = block.timestamp;
        TotalStaked += _amount;
        emit VoidStake(msg.sender, _amount); 
    }

    function unstake(uint256 _amount) external {
        StakerData storage user = Stakers[msg.sender];
        require(block.timestamp >= user.lastStaked + CooldownTime, "Cooldown period not met");
        require(user.balance >= _amount, "Insufficient staked balance");
        _safeTransferFrom(address(this), msg.sender, 1, _amount, "");
        user.balance -= _amount;
        TotalStaked -= _amount;
        emit VoidUnstake(msg.sender, _amount);
    }

    function getRemainingCooldownTime(address _user) public view returns (uint256) {
        uint256 lastStakedTime = Stakers[_user].lastStaked;
        if(block.timestamp < (lastStakedTime + CooldownTime)){
            return (lastStakedTime + CooldownTime) - block.timestamp;
        }
        return 0;   
    }

    function getStakerBalance(address _user) public view returns (uint256) {
        uint256 balance = Stakers[_user].balance;
        return (balance);
    }

    function sellVoidrite(uint256 amount) public nonReentrant {
        require(balanceOf(msg.sender, VOIDRITE) >= amount, "You cannot sell back more tokens than you hold");
        uint256 etherAmount = amount * SellPrice;
        require(address(this).balance >= etherAmount, "Contract does not have enough Ether to buy back the tokens");
        VoidritePool += amount;
        safeTransferFrom(msg.sender, address(this), VOIDRITE, amount, "");
        (bool success, ) = payable(msg.sender).call{value: etherAmount}("");
        require(success, "Ether Transfer failed");
        emit VoidSell(msg.sender, amount);
    }

    function buyVoidrite(uint256 amount) external payable nonReentrant {
        uint256 etherAmount = amount * BuyPrice;
        require(msg.value >= etherAmount, "Ether value sent is not correct");
        require((balanceOf(address(this), VOIDRITE) - TotalStaked) >= amount, "Contract does not have enough tokens to sell");
        _safeTransferFrom(address(this), msg.sender, VOIDRITE, amount, "");
        VoidritePool -= amount;
        emit VoidBuy(msg.sender, amount);
    }

    function EthPoolBalance() public view returns (uint256) {
        return address(this).balance;   
    }

    function WithdrawEther(uint256 _amount) external onlyAdmin {
        require(address(this).balance >= _amount, "Contract does not have enough Ether");
        payable(msg.sender).transfer(_amount);
    }

    function WithdrawTokens(uint256 amount) external onlyAdmin {
        require(balanceOf(address(this), VOIDRITE) >= amount, "Contract does not have enough tokens");
        _safeTransferFrom(address(this), msg.sender, VOIDRITE, amount, "");
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override  {
        require(id != VOIDTOUCHED,"You can't transfer that");
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        for (uint256 i = 0; i < ids.length; ++i) {
           require(ids[i] != VOIDTOUCHED,"You can't transfer that");
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 amount) public virtual override(ERC1155Burnable) {
        require(id != VOIDTOUCHED,"You can't burn that");
        super.burn(account, id, amount);   
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public virtual override {
        for (uint i = 0; i < ids.length; i++) {
             require(ids[i] != VOIDTOUCHED,"You can't burn that");
        }
        super.burnBatch(account, ids, amounts);
    }

    function CleanerBurn(address account, uint256 id, uint256 amount) public virtual {
        require(hasRole(CLEANER_ROLE, _msgSender()), "You must be a cleaner");
        emit VoidCleanse(account, amount);
        super._burn(account, id, amount);
    }

    function CleanerBurnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public virtual {
        require(hasRole(CLEANER_ROLE, _msgSender()), "You must be a cleaner");
        uint256 touchedCount = 0;
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == VOIDTOUCHED) {
                touchedCount++;
            }
        }
        emit VoidCleanse(account, touchedCount);
        super._burnBatch(account, ids, amounts);
    }

    function CleanerTransfer(address from, address to, uint256 id, uint256 amount) external {
        require(hasRole(CLEANER_ROLE, msg.sender), "Only cleaner can perform this action");
        super._safeTransferFrom(from, to, id, amount, "");
    } 

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        for (uint256 i = 0; i < ids.length; ++i) {
            if (from != address(0) && ids[i] == VOIDTOUCHED) {
                require(hasRole(CLEANER_ROLE, operator), "Only cleaner can perform this action");
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl, IERC165) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received( address, address, uint256, uint256, bytes calldata) external override returns(bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived( address, address, uint256[] memory, uint256[] memory, bytes calldata ) external override returns(bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

}