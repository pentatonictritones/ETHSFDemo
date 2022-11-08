// SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract TestCoin is ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable {
    bool public upgradeStatus;

    event MintUnderlying(uint256 indexed  amount, address indexed token, address indexed receiver);
    event BurnUnderlying(uint256 indexed amount, address indexed token, address indexed receiver);
    event OperatorMint(uint256 indexed amount, address indexed receiver);

    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mintUnderlying(uint256 amount, address token, address receiver) public returns (bool) {
        IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);
        emit MintUnderlying(amount, token, receiver);
        return true;
    }

    function redeemUnderlying(uint256 amount, address token, address receiver) public returns (bool) {
         IERC20Upgradeable(address(this)).transferFrom(msg.sender, address(this), amount);
         emit BurnUnderlying(amount, token, receiver);
         return true;
    }

    function operatorMint(uint256 amount, address receiver) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        _mint(receiver,amount);
        return true;
    }

    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
   
    
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(upgradeStatus, "Upgrade not allowed");
        upgradeStatus = false;
    }
}