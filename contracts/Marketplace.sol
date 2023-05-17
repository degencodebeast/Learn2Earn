// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "hardhat/console.sol";

contract Marketplace {
    struct course {
        uint256 price;
        uint256 royaltyFee;
        uint256 yield;
        address creator;
        string title;
    }

    struct specialization {
        course[] courses;
    }
}

/*
    nft - imported
    struct - courses
    struct - specialization 
    enum - course state - used to give rewards
    import reentrancy gaurd from openzeppelin

    Functions 

    create course - store course data / set royalte fee
    create specialization 
    update course 
    update specialization
    delete course
    delete specialization
    buy course - give royalties / mint and transfer nft 
    update state - when a course is completed and update nft uri
    dynamic yield - set yield dynamically
    update nft using chainlink automation / Automating payouts using chainlink automation

*/
