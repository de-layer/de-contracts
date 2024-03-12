//
//     ___         __
//    /   \___    / /  __ _ _   _  ___ _ __
//   / /\ / _ \  / /  / _` | | | |/ _ \ '__|
//  / /_//  __/ / /__| (_| | |_| |  __/ |
// /___,' \___| \____/\__,_|\__, |\___|_|
//                          |___/
//
//    Website: https://delayer.network/
//
//    Telegram: https://t.me/delayerevm
//    Twitter: https://twitter.com/delayerevm
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "./dOFT.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable;
}

contract DeLayerBridged is OFT {
    IDEXRouter public router;

    mapping(address => bool) public blacklisted;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) liquidityCreator;
    mapping(address => bool) isMaxBuyExempt;
    mapping(address => bool) liquidityPools;
    address public immutable pair;

    uint256 totalFee = 500;
    uint256 feeDenominator = 10000;

    // 1% of total supply
    uint256 maxBuyNumerator = 100;
    uint256 maxBuyDenominator = 10000;

    uint256 public launchedAt;
    bool isTradingAllowed = false;

    bool swapBackEnabled = false;

    address devWallet;
    modifier onlyDev() {
        require(_msgSender() == devWallet, "De Layer: Caller is not a team member");
        _;
    }

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event DistributedFees(uint256 fee);

    error DeLayerBlacklisted(address from, address to);
    error DeLayerTradingNotStarted();
    error DeLayerMaxBuyExceeded(uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        address _router
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        _allowances[owner()][_router] = type(uint256).max;
        _allowances[address(this)][_router] = type(uint256).max;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        liquidityCreator[owner()] = true;

        isMaxBuyExempt[owner()] = true;
        isMaxBuyExempt[address(this)] = true;
        isMaxBuyExempt[pair] = true;
        isMaxBuyExempt[_router] = true;
    }

    receive() external payable {}

    function decreaseFee(uint256 _newFee) external onlyDev {
        require(_newFee <= totalFee, "De Layer: Can't increase fee");
        totalFee = _newFee;
    }

    function setDevWallet(address _dev) external onlyOwner {
        devWallet = _dev;
    }

    function feeWithdrawal(uint256 amount) external onlyDev {
        uint256 amountETH = address(this).balance;
        payable(devWallet).transfer((amountETH * amount) / 100);
    }

    function startTrading() external onlyOwner {
        require(!isTradingAllowed);
        isTradingAllowed = true;
        launchedAt = block.number;
    }

    function _update(address from, address to, uint256 value) internal override {
        bool _shouldTakeFee = false;
        bool _shouldSwapBack = false;

        if (from != address(0) && to != address(0)) {
            if (blacklisted[from] || blacklisted[to]) {
                revert DeLayerBlacklisted(from, to);
            }
            if (launchedAt == 0 && liquidityPools[to]) {
                if (!liquidityCreator[from]) {
                    revert DeLayerTradingNotStarted();
                }
                launchedAt = block.number;
            }
            if (!isTradingAllowed && !liquidityCreator[from] && !liquidityCreator[to]) {
                revert DeLayerTradingNotStarted();
            }

            if (!inSwap) {
                if (liquidityPools[from] && !isMaxBuyExempt[to] && value > (1_000_000 ether)) {
                    revert DeLayerMaxBuyExceeded(value);
                }
                _shouldTakeFee = !isFeeExempt[from];
                if (shouldSwapBack(to) && value > 0) {
                    _shouldSwapBack = true;
                }
            }
        }

        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        uint256 valueReceived = _shouldTakeFee ? receiveFee(from, to, value) : value;

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += valueReceived;
            }
        }

        emit Transfer(from, to, valueReceived);
    }

    function receiveFee(address from, address to, uint256 amount) internal returns (uint256) {
        bool sellingOrBuying = liquidityPools[from] || liquidityPools[to];

        if (!sellingOrBuying) {
            return amount;
        }

        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        _balances[address(this)] += feeAmount;

        return amount - feeAmount;
    }

    function shouldSwapBack(address to) internal view returns (bool) {
        return !liquidityPools[msg.sender] && !inSwap && liquidityPools[to] && swapBackEnabled;
    }

    function setProvideLiquidity(address lp, bool isPool) external onlyDev {
        require(lp != pair, "De Layer: Can't alter current liquidity pair");
        liquidityPools[lp] = isPool;
    }

    function setSwapBackEnabled(bool _enabled) external onlyDev {
        swapBackEnabled = _enabled;
    }

    function setMaxBuyExempt(address _address, bool _isExempt) external onlyDev {
        isMaxBuyExempt[_address] = _isExempt;
    }

    function swapBack() internal swapping {
        uint256 myBalance = balanceOf(address(this));

        if (myBalance == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(myBalance, 0, path, address(this), block.timestamp);

        emit DistributedFees(myBalance);
    }

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklisted[_address] = _isBlacklisted;
    }

    function addLiquidityCreator(address _liquidityCreator) external onlyOwner {
        liquidityCreator[_liquidityCreator] = true;
    }
}
