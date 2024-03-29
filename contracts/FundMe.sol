// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FundMe {
    using SafeMathChainlink for uint256;
    // using SafeMath for uint256;

    address public owner;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 1_000_000_000_000_000_000;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Price of ETH/USD on Rinkeby
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // returns 8 decimal places
        return uint256(answer * 10_000_000_000); // add 10 more decimal places to convert this unit to wei (18 zeroes)
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minUSD = 50 * 1_000_000_000_000_000_000;
        uint256 price = getPrice();
        uint256 precision = 1 * 1_000_000_000_000_000_000;
        return (minUSD * precision) / price;
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountinUsd = (ethPrice * ethAmount) /
            1_000_000_000_000_000_000;
        return ethAmountinUsd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}