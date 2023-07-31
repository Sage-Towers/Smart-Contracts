// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LogicalMechanism is ERC20, ERC20Burnable, Pausable, AccessControl {

    bytes32 constant MINTER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bool public taxes = false;// Tax every transfer
    bool public taxesPositive = false;// True forces a higer transfer, so if takes are 10% and you send 100 you will need 110. Else we would send 90.
    bool public burnTaxes = false;// Burn instead of sending to tax collector
    bool public claimTaxes = false;// Just mints bonus for the tax collector
    uint256 public taxRate = 10;// 10 = 1%
    address public taxCollector;

    constructor(uint256 adminAmount) ERC20("Logical Mechanism", "LLM") {
        taxCollector =  msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender,adminAmount);
    }

    function setTaxRate(uint256 newTaxRate) public onlyRole(ADMIN_ROLE) {
        taxRate = newTaxRate;
    }

    function setTaxes(bool useTax) public onlyRole(ADMIN_ROLE) {
        taxes = useTax;
    }

    function setBurnTaxes(bool _burnTaxes) public onlyRole(ADMIN_ROLE) {
        burnTaxes = _burnTaxes;
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

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override{
        super._beforeTokenTransfer(from, to, amount);
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

    //MINTER_ROLE is a GM unless ADMIN_ROLE stops them
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
    }
    
    function minterTransfer(address from, address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused {
        _transfer(from, to, amount);
    }

    function minterBurn(address from, uint256 value) public onlyRole(MINTER_ROLE) whenNotPaused {
        _burn(from, value);
    }
    //End of GM

    function rescueETH(address to,uint256 amount) external onlyRole(ADMIN_ROLE) {
        payable(to).transfer(amount);
    }

    function rescueERC20(address to, address tokenAdd, uint256 amount) external onlyRole(ADMIN_ROLE) {
        IERC20(tokenAdd).transfer(to, amount);
    }

}