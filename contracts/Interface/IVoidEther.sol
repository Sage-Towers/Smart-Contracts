// SPDX-License-Identifier: MIT
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IVoidEther {

event Approval( address indexed owner,address indexed spender,uint256 value ) ;
event Paused( address account ) ;
event RoleAdminChanged( bytes32 indexed role,bytes32 indexed previousAdminRole,bytes32 indexed newAdminRole ) ;
event RoleGranted( bytes32 indexed role,address indexed account,address indexed sender ) ;
event RoleRevoked( bytes32 indexed role,address indexed account,address indexed sender ) ;
event Transfer( address indexed from,address indexed to,uint256 value ) ;
event Unpaused( address account ) ;
function CooldownTime(  ) external view returns (uint256 ) ;
function DEFAULT_ADMIN_ROLE(  ) external view returns (bytes32 ) ;
function LastStaked( address  ) external view returns (uint256 ) ;
function StakedBalance( address  ) external view returns (uint256 ) ;
function Stakers( uint256  ) external view returns (address ) ;
function TotalStaked(  ) external view returns (uint256 ) ;
function addSeason( uint256 duration,uint256 reward ) external   ;
function allowance( address owner,address spender ) external view returns (uint256 ) ;
function approve( address spender,uint256 amount ) external  returns (bool ) ;
function balanceOf( address account ) external view returns (uint256 ) ;
function burn( uint256 amount ) external   ;
function burnFrom( address account,uint256 amount ) external   ;
function burnTaxes(  ) external view returns (bool ) ;
function checkReward( address user ) external view returns (uint256 ) ;
function claimRewards(  ) external   ;
function claimTaxes(  ) external view returns (bool ) ;
function contractStartTime(  ) external view returns (uint256 ) ;
function decimals(  ) external view returns (uint8 ) ;
function decreaseAllowance( address spender,uint256 subtractedValue ) external  returns (bool ) ;
function getMultiplier(  ) external view returns (uint256 ) ;
function getRemainingCooldownTime( address _user ) external view returns (uint256 ) ;
function getRoleAdmin( bytes32 role ) external view returns (bytes32 ) ;
function getStakersWithBalance(  ) external view returns (address[] memory ) ;
function getVoidriteBalance(  ) external view returns (uint256 ) ;
function grantRole( bytes32 role,address account ) external   ;
function hasRole( bytes32 role,address account ) external view returns (bool ) ;
function hasTokensStaked( address _user ) external view returns (bool ) ;
function increaseAllowance( address spender,uint256 addedValue ) external  returns (bool ) ;
function lastClaimed( address  ) external view returns (uint256 ) ;
function lastUnlockTime( address  ) external view returns (uint256 ) ;
function mint( address to,uint256 amount ) external   ;
function minterBurn( address from,uint256 value ) external   ;
function minterTransfer( address from,address to,uint256 amount ) external   ;
function name(  ) external view returns (string memory ) ;
function onERC1155BatchReceived( address ,address ,uint256[] memory ,uint256[] memory ,bytes memory  ) external  returns (bytes4 ) ;
function onERC1155Received( address ,address ,uint256 ,uint256 ,bytes memory  ) external  returns (bytes4 ) ;
function pause(  ) external   ;
function paused(  ) external view returns (bool ) ;
function removeSeason( uint256 index ) external   ;
function renounceRole( bytes32 role,address account ) external   ;
function rescueERC20( address to,address tokenAdd,uint256 amount ) external   ;
function rescueETH( address to,uint256 amount ) external   ;
function revokeRole( bytes32 role,address account ) external   ;
function rewardDecimals(  ) external view returns (uint256 ) ;
function rewards( address  ) external view returns (uint256 ) ;
function seasons( uint256  ) external view returns (uint256 duration, uint256 reward) ;
function setBurnTaxes( bool _burnTaxes ) external   ;
function setClaimTaxes( bool useTax ) external   ;
function setCooldown( uint256 newCooldown ) external   ;
function setRewardDecimals( uint256 decimals ) external   ;
function setTaxCollector( address newTaxCollector ) external   ;
function setTaxRate( uint256 newTaxRate ) external   ;
function setTaxes( bool useTax ) external   ;
function setTaxesPositive( bool useTaxPos ) external   ;
function setVoidrite( address newAddress ) external   ;
function stake( uint256 _amount ) external   ;
function supportsInterface( bytes4 interfaceId ) external view returns (bool ) ;
function symbol(  ) external view returns (string memory ) ;
function taxCollector(  ) external view returns (address ) ;
function taxRate(  ) external view returns (uint256 ) ;
function taxes(  ) external view returns (bool ) ;
function taxesPositive(  ) external view returns (bool ) ;
function totalSupply(  ) external view returns (uint256 ) ;
function transfer( address to,uint256 amount ) external  returns (bool ) ;
function transferFrom( address from,address to,uint256 amount ) external  returns (bool ) ;
function unpause(  ) external   ;
function unstake( uint256 _amount ) external   ;
function updateSeason( uint256 index,uint256 duration,uint256 reward ) external   ;
}