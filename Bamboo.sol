// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bamboo is ERC20Burnable, Ownable {
    string private constant SYMBOL = "BAM";
    string private constant NAME = "Bamboo";
    uint256 private constant INITIAL_SUPPLY = 100000000 * 10**9; // 100 million, precision 9
    uint256 private constant INITIAL_FEE = 20;
    uint256 private constant PRECISION = 10**9;
    uint256 private constant PERCENT = 100;
    address private constant NULL_ADDRESS = address(0);

    uint256 public feeBuy;
    uint256 public feeSell;
    address public pool;
    address public devWallet;

    mapping(address => bool) public excludedFromFees;

    event Deployed(address sender, string symbol, string name);
    event SetExcluded(address sender, address user, bool excluded);
    event SetBuyFee(address sender, uint256 fee);
    event SetSellFee(address sender, uint256 fee);
    event SetDevWallet(address sender, address devWallet);
    event SetPool(address sender, address pool);

    constructor() ERC20(SYMBOL, NAME) {
        _mint(_msgSender(), INITIAL_SUPPLY);
        _setBuyFeePercent(INITIAL_FEE);
        _setSellFeePercent(INITIAL_FEE);
        emit Deployed(_msgSender(), SYMBOL, NAME);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setExcluded(address user, bool excluded) external onlyOwner {
        excludedFromFees[user] = excluded;
        emit SetExcluded(_msgSender(), user, excluded);
    }

    function setBuyFeePercent(uint256 feePercent) public onlyOwner {
        require(
            feePercent < feeBuy,
            "Bamboo::setBuyFeePercent: can only reduce transaction fees"
        );
        _setBuyFeePercent(feePercent);
    }

    function setSellFeePercent(uint256 feePercent) public onlyOwner {
        require(
            feePercent < feeSell,
            "Bamboo::setSellFeePercent: can only reduce transaction fees"
        );
        _setSellFeePercent(feePercent);
    }

    function _setBuyFeePercent(uint256 feePercent) private {
        feeBuy = feePercent;
        emit SetBuyFee(_msgSender(), feePercent);
    }

    function _setSellFeePercent(uint256 feePercent) private {
        feeSell = feePercent;
        emit SetSellFee(_msgSender(), feePercent);
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
        emit SetDevWallet(_msgSender(), _devWallet);
    }

    function setPool(address _pool) external onlyOwner {
        pool = _pool;
        emit SetPool(_msgSender(), _pool);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        address lpPool = pool;
        address feeWallet = devWallet;
        require(lpPool != NULL_ADDRESS, "Bamboo::_transfer: pool unitialized");
        require(
            feeWallet != NULL_ADDRESS,
            "Bamboo::_transfer: devWallet unitialized"
        );
        if (sender == lpPool) {
            if (!excludedFromFees[recipient]) {
                uint256 devAmount = (amount * feeBuy) / PERCENT;
                amount = amount - devAmount;
                if (devAmount > 0)
                    ERC20._transfer(sender, feeWallet, devAmount);
            }
        } else if (recipient == lpPool) {
            if (!excludedFromFees[sender]) {
                uint256 devAmount = (amount * feeSell) / PERCENT;
                amount = amount - devAmount;
                if (devAmount > 0)
                    ERC20._transfer(sender, feeWallet, devAmount);
            }
        }
        ERC20._transfer(sender, recipient, amount);
    }
}
