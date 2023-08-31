// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SubscriptionService is Ownable {
    IERC20 public token;
    uint256 public initialPrice = 1 ether; // Preço inicial é 1 Ether

    struct Subscription {
        uint256 depositAmount;
        uint256 startDate;
        uint256 durationInDays;
        bool isActive;
    }

    mapping(address => Subscription) public subscriptions;
    address[] public users;

    event SubscriptionStarted(
        address indexed user,
        uint256 depositAmount,
        uint256 startDate,
        uint256 durationInDays
    );
    event SubscriptionCancelled(address indexed user, uint256 refundAmount);
    event TokensWithdrawn(
        address indexed owner,
        address indexed tokenAddress,
        uint256 amount
    );
    event PriceChanged(uint256 oldPrice, uint256 startDate, uint256 newPrice);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        initialPrice = newPrice;
        emit PriceChanged(initialPrice, block.timestamp, newPrice);
    }

    function startSubscription(uint256 durationInDays) external {
        require(durationInDays > 0, "Duration must be greater than 0");
        require(!subscriptions[msg.sender].isActive, "Subscription already exists");

        uint256 depositAmount = initialPrice * durationInDays;

        // Transfer tokens from user to contract
        require(token.transferFrom(msg.sender, address(this), depositAmount), "Token transfer failed");

        subscriptions[msg.sender] = Subscription({
            depositAmount: depositAmount,
            startDate: block.timestamp,
            durationInDays: durationInDays,
            isActive: true
        });

        users.push(msg.sender);

        emit SubscriptionStarted(
            msg.sender,
            depositAmount,
            block.timestamp,
            durationInDays
        );
    }

    function getTimeLeft(address user) external view returns (uint256) {
        Subscription storage subscription = subscriptions[user];
        uint256 elapsedTime = block.timestamp - subscription.startDate;
        if (elapsedTime >= subscription.durationInDays * 1 days) {
            return 0;
        } else {
            return (subscription.durationInDays * 1 days) - elapsedTime;
        }
    }

    function cancelSubscription() external {
        Subscription storage subscription = subscriptions[msg.sender];
        uint256 elapsedTime = block.timestamp - subscription.startDate;

        require(
            elapsedTime < subscription.durationInDays * 1 days,
            "Subscription already expired"
        );

        uint256 refundAmount = (subscription.depositAmount *
            (subscription.durationInDays * 1 days - elapsedTime)) /
            (subscription.durationInDays * 1 days);

        subscription.isActive = false;
        token.transfer(msg.sender, refundAmount);
        emit SubscriptionCancelled(msg.sender, refundAmount);
    }

    function increaseSubscription(uint256 additionalDays) external {
        require(additionalDays > 0, "Additional days must be greater than 0");
        require(subscriptions[msg.sender].depositAmount > 0, "No active subscription");

        Subscription storage subscription = subscriptions[msg.sender];

        uint256 elapsedTime = block.timestamp - subscription.startDate;
        uint256 refundAmount = (subscription.depositAmount * (subscription.durationInDays * 1 days - elapsedTime)) / (subscription.durationInDays * 1 days);

        uint256 additionalDeposit = initialPrice * additionalDays;
        uint256 newDepositAmount = subscription.depositAmount + additionalDeposit;
        uint256 newDurationInDays = subscription.durationInDays + additionalDays;

        // Transfer additional tokens from the user to the contract
        require(token.transferFrom(msg.sender, address(this), additionalDeposit), "Token transfer failed");

        // Update the subscription with the new values
        subscription.depositAmount = newDepositAmount;
        subscription.durationInDays = newDurationInDays;

        // Emit an event indicating the subscription increase
        emit SubscriptionStarted(
            msg.sender,
            newDepositAmount,
            block.timestamp,
            newDurationInDays
        );

        // Refund the previously refundable amount
        if (refundAmount > 0) {
            token.transfer(msg.sender, refundAmount);
        }
    }

    function withdrawPaymentTokens() external onlyOwner {
        uint256 totalAvailable = token.balanceOf(address(this));

        uint256 totalRefundable = calculateTotalRefundable();

        require(
            totalAvailable > totalRefundable,
            "No withdrawable amount available"
        );

        uint256 withdrawAmount = totalAvailable - totalRefundable;

        token.transfer(owner(), withdrawAmount);

        emit TokensWithdrawn(owner(), address(token), withdrawAmount);
    }

    function withdrawAnyERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(token), "Cannot withdraw payment token");
        IERC20 otherToken = IERC20(tokenAddress);
        uint256 contractBalance = otherToken.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient balance");
        otherToken.transfer(owner(), amount);
        emit TokensWithdrawn(owner(), tokenAddress, amount);
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
        emit TokensWithdrawn(owner(), address(0), amount);
    }

    function calculateTotalRefundable() internal view returns (uint256) {
        uint256 totalRefundable = 0;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            Subscription storage subscription = subscriptions[user];
            uint256 elapsedTime = block.timestamp - subscription.startDate;

            if (elapsedTime < subscription.durationInDays * 1 days) {
                totalRefundable +=
                    (subscription.depositAmount *
                        (subscription.durationInDays * 1 days - elapsedTime)) /
                    (subscription.durationInDays * 1 days);
            }
        }
        return totalRefundable;
    }
}
