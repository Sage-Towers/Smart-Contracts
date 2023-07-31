// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IVoidrite {
    function getStakerBalance(address _user) external view returns (uint256);
}

contract VoidEther is ERC20, ERC20Burnable, Pausable, AccessControl, ReentrancyGuard {

    bytes32 constant MINTER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bool public taxes = true;// Tax every transfer, can be used as a sudo anti-whale
    bool public taxesPositive = true;// True forces a higer transfer, so if takes are 10% and you send 100 you will need 110. Else we would send 90.
    bool public burnTaxes = false;// Burn instead of sending to tax collector
    bool public claimTaxes = true;// Just mints bonus for the tax collector
    uint256 public taxRate = 70;// 7% because we diveded by 1000 for more granularity
    address public taxCollector;
    struct Season {
        uint256 duration;
        uint256 reward;
    }       
    Season[] public seasons;
    uint256 public rewardDecimals =14;
    IVoidrite private voidrite = IVoidrite(0x3ab85c1ED41A9f8275f7a446DaF5D7426e8eC839);
    uint256 public contractStartTime;
    mapping(address => bool) private hasClaimed;
    mapping(address => uint256) public lastClaimed; 
    mapping(address => uint256) public lastUnlockTime;

    constructor(uint256 adminSupply) ERC20("Void Ether", "VETH") {
        contractStartTime = block.timestamp;
        taxCollector =  msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender,adminSupply);
        seasons.push(Season({duration: 3 * 30 days, reward: 100})); // Season 1
        seasons.push(Season({duration: 2 * 3 * 30 days, reward: 90})); // Season 2
        seasons.push(Season({duration: 3 * 3 * 30 days, reward: 70})); // Season 3
        seasons.push(Season({duration: 4 * 3 * 30 days, reward: 50})); // Season 4
        seasons.push(Season({duration: 5 * 3 * 30 days, reward: 30})); // Season 5
        seasons.push(Season({duration: 6 * 3 * 30 days, reward: 20})); // Season 6
        seasons.push(Season({duration: 7 * 3 * 30 days, reward: 10})); // Season 7
        seasons.push(Season({duration: 8 * 3 * 30 days, reward: 5})); // Season 8
        seasons.push(Season({duration: 16 * 3 * 30 days, reward: 2})); // Season 9
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function setVoidrite(address newAddress) public onlyRole(ADMIN_ROLE) {
        voidrite = IVoidrite(newAddress);
    }

    function setTaxRate(uint256 newTaxRate) public onlyRole(ADMIN_ROLE) {
        taxRate = newTaxRate;
    }

    function setBurnTaxes(bool _burnTaxes) public onlyRole(ADMIN_ROLE) {
        burnTaxes = _burnTaxes;
    }

    function setTaxes(bool useTax) public onlyRole(ADMIN_ROLE) {
        taxes = useTax;
    }

    function setTaxesPositive(bool useTaxPos) public onlyRole(ADMIN_ROLE) {
        taxesPositive = useTaxPos;
    }

    function setClaimTaxes(bool useTax) public onlyRole(ADMIN_ROLE) {
        claimTaxes = useTax;
    }

    function setTaxCollector(address newTaxCollector) public onlyRole(ADMIN_ROLE) {
        taxCollector = newTaxCollector;
    }

    function setRewardDecimals(uint256 decimals) public onlyRole(ADMIN_ROLE) {
        rewardDecimals = decimals;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if(taxes){
            if(taxesPositive){
                uint256 taxAmount = amount*(taxRate)/(1000);
                require(balanceOf(msg.sender)>(amount+taxAmount), "Balance too low for tax");
                    if(burnTaxes){
                        _burn(msg.sender,taxAmount);
                    }else{
                        super.transfer(taxCollector, taxAmount);
                    }
                return super.transfer(to, amount);
            }
        else{
                uint256 taxAmount = amount*(taxRate)/(1000);
                uint256 sendAmount = amount-(taxAmount);
                    if(burnTaxes){
                        _burn(msg.sender,taxAmount);
                        }else{
                        super.transfer(taxCollector, taxAmount);
                    }
                return super.transfer(to, sendAmount);
            }
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if(taxes){
            if(taxesPositive){
                uint256 taxAmount = amount*(taxRate)/(1000);
                require(balanceOf(from)>(amount+taxAmount), "Balance too low for tax");
                    if(burnTaxes){
                        _burn(from,taxAmount);
                    }else{
                        super.transfer(taxCollector, taxAmount);
                    }
                return super.transfer(to, amount);
            }
        else{
                uint256 taxAmount = amount * taxRate / 1000;
                uint256 sendAmount = amount - taxAmount;
                    if(burnTaxes){
                        _burn(msg.sender,taxAmount);
                    }else{
                        super.transferFrom(from, taxCollector, taxAmount);
                    }
                return super.transferFrom(from, to, sendAmount);
            }
        }
        return super.transferFrom(from, to, amount);
    }

    function minterTransfer(address from, address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _transfer(from, to, amount);
    }

    function minterBurn(address from, uint256 value) public onlyRole(MINTER_ROLE) {
        _burn(from, value);
    }

    function rescueETH(address to,uint256 amount) external onlyRole(ADMIN_ROLE) {
        payable(to).transfer(amount);
    }

    function rescueERC20(address to, address tokenAdd, uint256 amount) external onlyRole(ADMIN_ROLE) {
        IERC20(tokenAdd).transfer(to, amount);
    }


    /*                       Voidrite Rewards                     */

    function initializeClaim(address user) public {
        require(lastClaimed[user] == 0, "Staker is already initialized.");    
        uint256 stake = voidrite.getStakerBalance(user);
        require(stake > 0, "No Voidrite staked");
        lastClaimed[user] = block.timestamp;
    }

    function claimRewards() public nonReentrant {
        uint256 stake = voidrite.getStakerBalance(msg.sender);
        require(stake > 0, "No Voidrite staked");
            if (hasClaimed[msg.sender]) {
                uint256 multiplier = getMultiplier();
                uint256 rewardAmount;
                rewardAmount = stake * (block.timestamp - lastClaimed[msg.sender]) * multiplier * 10**rewardDecimals;
                _mint(msg.sender, rewardAmount);
                if(claimTaxes){
                    _mint(taxCollector, rewardAmount / taxRate);
                }
            } else {
                hasClaimed[msg.sender] = true;
            }
        lastClaimed[msg.sender] = block.timestamp;
    }

    function checkReward(address user) public view returns (uint256) {
        if (lastClaimed[msg.sender]<1) {
            return 0;
        }
        uint256 stake = voidrite.getStakerBalance(user);
        uint256 multiplier = getMultiplier();
        uint256 reward;
        reward = stake * (block.timestamp - lastClaimed[msg.sender]) * multiplier * 10**rewardDecimals;
        return reward;
    }
  
    function getMultiplier() public view returns (uint256) {
        uint256 timePassed = block.timestamp - contractStartTime;
        uint256 elapsed = 0;
        for (uint256 i = 0; i < seasons.length; i++) {
            elapsed += seasons[i].duration;
            if (timePassed < elapsed) {
                return seasons[i].reward;
            }
        }
        return 1;
    }

    function addSeason(uint256 duration, uint256 reward) public onlyRole(ADMIN_ROLE) {
        seasons.push(Season({duration: duration, reward: reward}));
    }

    function removeSeason(uint256 index) public onlyRole(ADMIN_ROLE) {
        require(index < seasons.length, "Season index out of range");
        if (index == seasons.length - 1) {
            seasons.pop();
            return;
        }
        seasons[index] = seasons[seasons.length - 1];
        seasons.pop();
    }

    function updateSeason(uint256 index, uint256 duration, uint256 reward) public onlyRole(ADMIN_ROLE) {
        require(index < seasons.length, "Season index out of range");
        seasons[index] = Season({duration: duration, reward: reward});
    }

}