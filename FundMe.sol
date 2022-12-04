//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConvertor.sol";

error NotOwner();

contract FundMe{

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address public immutable i_owner;

    constructor(){
        i_owner = msg.sender;
    }

    address[] public funders;
    mapping(address => uint256) public addressToAmtFund;

    function fund() public payable{
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        addressToAmtFund[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner{
        
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmtFund[funder] = 0;
        }
        funders = new address[](0);

        //transfer - returns error if gas > 2300, automatically reverts
        payable(msg.sender).transfer(address(this).balance);
        //send - returns bool if gas >2300
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send Failed");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Send Failed");
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not the owner");
        if(msg.sender != i_owner){
            revert NotOwner();
        }
        _; // do the rest of the code
    }

    //do the below if someone sends ETH to the contract without calling fund.
    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }
}