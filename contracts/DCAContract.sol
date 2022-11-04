// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IIbAlluo.sol";

import "./interfaces/superfluid/ISuperfluid.sol";
import "./interfaces/superfluid/ISuperfluidToken.sol";
import "./interfaces/superfluid/ISuperfluid.sol";
import "./interfaces/superfluid/IConstantFlowAgreementV1.sol";
import "./interfaces/superfluid/IInstantDistributionAgreementV1.sol";

import {CFAv1Library} from "./superfluid/libs/CFAv1Library.sol";
import {IDAv1Library} from "./superfluid/libs/IDAv1Library.sol";

import "hardhat/console.sol";

interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC1820RegistryUpgradeable {
    function setInterfaceImplementer(address a, bytes32 b, address c) external;
}


contract DCAContract is AccessControlUpgradeable, IERC777Recipient {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CFAv1Library for CFAv1Library.InitData;
    using IDAv1Library for IDAv1Library.InitData;
    using Address for address;

    bytes32 public constant CFA_ID = keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    address public constant superfluidHost = 0x3E14dC1b13c488a8d5D310918780c983bD5982E7;
    address public ibAlluoFrom;
    address public ibAlluoTo;
    address public ricochetDCAContract;

    CFAv1Library.InitData public cfaV1Lib;
    IDAv1Library.InitData public idaV1Lib;
    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    constructor(address _ibAlluoFrom, address _ibAlluoTo, address _ricochetDCAContract)  {
        ibAlluoFrom = _ibAlluoFrom;
        ibAlluoTo = _ibAlluoTo;
        ricochetDCAContract = _ricochetDCAContract;


        // Initialise key Superfluid parameters
        ISuperfluid host = ISuperfluid(superfluidHost);
        cfaV1Lib = CFAv1Library.InitData(
            host,
            IConstantFlowAgreementV1(address(host.getAgreementClass(CFA_ID)))
        );
        idaV1Lib = IDAv1Library.InitData(host, IInstantDistributionAgreementV1(address(host.getAgreementClass(0x8aedc3b5d4bf031e11a7e2940f7251c005698405d58e02e1c247fed3b1b3a674))));

        // // Grant permissions to the ibAlluo contract to create streams on your behalf
        bytes memory data = IIbAlluo(_ibAlluoFrom).formatPermissions();
        host.callAgreement(host.getAgreementClass(CFA_ID), data, "0x");

        // // Grant permissions so that Ricochet's DCA contract can airdrop you tokens 
        idaV1Lib.approveSubscription(ISuperfluidToken(IIbAlluo(ibAlluoTo).superToken()), ricochetDCAContract, 1);
        idaV1Lib.approveSubscription(ISuperfluidToken(0x263026E7e53DBFDce5ae55Ade22493f828922965), ricochetDCAContract, 3);

        // Set up ERC777 Recipient
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getIbAlluoFrom(uint256 amount, address token) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256){
        uint256 balanceBefore = IIbAlluo(token).balanceOf(address(this));
        IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(token).safeIncreaseAllowance(ibAlluoFrom, amount);
        IIbAlluo(ibAlluoFrom).deposit(token, amount);
        uint256 balanceAfter = IIbAlluo(token).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    function startDCAStream(int96 flowRatePerSecond) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        IIbAlluo(ibAlluoFrom).createFlow(ricochetDCAContract, flowRatePerSecond,  IIbAlluo(ibAlluoFrom).balanceOf(address(this)));
    }

    function endDCAStream() public onlyRole(DEFAULT_ADMIN_ROLE)  {
        IIbAlluo(ibAlluoFrom).deleteFlow(ricochetDCAContract);
    }

    function checkBalances() public view returns (int256 ibAlluoFromRealTimeBalance, int256 ibAlluoToRealtimeBalance) {
        ibAlluoFromRealTimeBalance = IIbAlluo(ibAlluoFrom).getBalance(address(this));
        ibAlluoToRealtimeBalance = IIbAlluo(ibAlluoTo).getBalance(address(this));
    }

    function transferAllFunds() public onlyRole(DEFAULT_ADMIN_ROLE) {
        (int256 ibAlluoFromRealTimeBalance, int256 ibAlluoToRealtimeBalance) = checkBalances();

        IIbAlluo(ibAlluoFrom).transfer(msg.sender, uint256(ibAlluoFromRealTimeBalance));
        IIbAlluo(ibAlluoTo).transfer(msg.sender, uint256(ibAlluoToRealtimeBalance));
    }


    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = destinations.length;
        require(length == calldatas.length, "DCAContract: lengths");
        for (uint256 i = 0; i < length; i++) {
            destinations[i].functionCall(calldatas[i]);
        }
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
    }
}
