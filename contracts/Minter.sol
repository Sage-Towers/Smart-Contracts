// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMint {
    function mint(address to, string memory rng) external;
}

interface IToken {
    function minterTransfer(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract Minter is ReentrancyGuard, AccessControl {
    IMint public nftToken;
    IToken public paymentToken;
    uint256 public price = 10 ether;
    uint256 public maxSupply = 1000;
    uint256 public totalMinted;

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    constructor() {
        paymentToken = IToken(0xCb164D4512E87C6c190f01B32c26FB3BC143b88e);
        nftToken = IMint(0x786591395a50E5f3De4eF6014D6E2012D339EbeB);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SETTER_ROLE, msg.sender);
    }

    function setPrice(uint256 _price) public onlyRole(SETTER_ROLE) {
        price = _price;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(SETTER_ROLE) {
        maxSupply = _maxSupply;
    }
    
    function setNftToken(address addy) public onlyRole(SETTER_ROLE) {
          nftToken = IMint(addy);
    }

    function setPaymentToken(address addy) public onlyRole(SETTER_ROLE) {
          paymentToken = IToken(addy);
    }

    function mintNFT(address to, string memory rng) public nonReentrant {
        require(totalMinted < maxSupply, "Maximum supply reached");
        require(paymentToken.balanceOf(msg.sender)>=price, "Not enough payment");
        paymentToken.minterTransfer(msg.sender, address(this), price);
        nftToken.mint(to, rng);
        totalMinted += 1;
    }
    
    function rescueETH(address to,uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(to).transfer(amount);
    }

    function rescueERC20(address to, address tokenAdd, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAdd).transfer(to, amount);
    }

}
