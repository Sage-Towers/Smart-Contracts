// SPDX-License-Identifier: MIT
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IMinter {

event RoleAdminChanged( bytes32 indexed role,bytes32 indexed previousAdminRole,bytes32 indexed newAdminRole ) ;
event RoleGranted( bytes32 indexed role,address indexed account,address indexed sender ) ;
event RoleRevoked( bytes32 indexed role,address indexed account,address indexed sender ) ;
function DEFAULT_ADMIN_ROLE(  ) external view returns (bytes32 ) ;
function SETTER_ROLE(  ) external view returns (bytes32 ) ;
function getRoleAdmin( bytes32 role ) external view returns (bytes32 ) ;
function grantRole( bytes32 role,address account ) external   ;
function hasRole( bytes32 role,address account ) external view returns (bool ) ;
function maxSupply(  ) external view returns (uint256 ) ;
function mintNFT( address to,string memory rng ) external   ;
function nftToken(  ) external view returns (address ) ;
function paymentToken(  ) external view returns (address ) ;
function price(  ) external view returns (uint256 ) ;
function renounceRole( bytes32 role,address account ) external   ;
function rescueERC20( address to,address tokenAdd,uint256 amount ) external   ;
function rescueETH( address to,uint256 amount ) external   ;
function revokeRole( bytes32 role,address account ) external   ;
function setMaxSupply( uint256 _maxSupply ) external   ;
function setNftToken( address addy ) external   ;
function setPaymentToken( address addy ) external   ;
function setPrice( uint256 _price ) external   ;
function supportsInterface( bytes4 interfaceId ) external view returns (bool ) ;
function totalMinted(  ) external view returns (uint256 ) ;
}