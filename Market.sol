// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory n, string memory s) ERC20(n, s) {}
    function faucet() external { _mint(msg.sender, 1000 ether); }
}

contract P2PMarket {
    using SafeERC20 for IERC20;

    struct Order {
        address maker;
        IERC20 sellToken;
        uint256 sellAmount;
        IERC20 buyToken;
        uint256 buyAmount;
        uint64 expiry;
        bool open;
    }

    Order[] public orders;

    event Created(uint256 indexed id, address indexed maker, address sellToken, uint256 sellAmount, address buyToken, uint256 buyAmount, uint64 expiry);
    event Filled(uint256 indexed id, address indexed taker);
    event Cancelled(uint256 indexed id);

    function createOrder(
        IERC20 sellToken, uint256 sellAmount,
        IERC20 buyToken, uint256 buyAmount,
        uint64 duration
    ) external returns (uint256 id) {
        require(sellAmount > 0 && buyAmount > 0, "zero amount");
        sellToken.safeTransferFrom(msg.sender, address(this), sellAmount);
        uint64 exp = uint64(block.timestamp) + duration;
        orders.push(Order(msg.sender, sellToken, sellAmount, buyToken, buyAmount, exp, true));
        id = orders.length - 1;
        emit Created(id, msg.sender, address(sellToken), sellAmount, address(buyToken), buyAmount, exp);
    }

    function fillOrder(uint256 id) external {
        Order storage o = orders[id];
        require(o.open, "closed");
        require(block.timestamp <= o.expiry, "expired");
        o.open = false;
        o.buyToken.safeTransferFrom(msg.sender, o.maker, o.buyAmount);
        o.sellToken.safeTransfer(msg.sender, o.sellAmount);
        emit Filled(id, msg.sender);
    }

    function cancelOrder(uint256 id) external {
        Order storage o = orders[id];
        require(o.open, "closed");
        require(msg.sender == o.maker || block.timestamp > o.expiry, "not allowed");
        o.open = false;
        o.sellToken.safeTransfer(o.maker, o.sellAmount);
        emit Cancelled(id);
    }

    function orderCount() external view returns (uint256) { return orders.length; }
}