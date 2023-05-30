// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Unauthorized();
error PriceNotMet(uint256 price);

contract LearningPlatform is ReentrancyGuard, Ownable {
    enum State {
        Closed,
        Open,
        Finished
    }

    struct Course {
        uint256 price;
        uint256 royaltyFee;
        uint256 yieldRate;
        uint256 completionReward;
        address creator;
        bool exists;
        string uri;
    }

    struct Degree {
        uint256[] courseIds;
        uint256 price;
        bool exists;
    }

    mapping(uint256 => Course) public courses;
    mapping(uint256 => Degree) public degrees;
    mapping(address => uint256) public studentBalances;
    mapping(address => mapping(uint256 => State)) public studentToCourseState;
    mapping(address => mapping(uint256 => State)) public studentToDegreeState;
    mapping(uint256 => uint256) public CoursePurchases; // courseId => number of students
    mapping(uint256 => uint256) public CourseCompletions; // courseId => number of students

    IERC20 public usdcToken;
    State courseState;
    State degreeState;
    address payable public immutable i_daoAddress;

    constructor(address _usdcToken, address payable _daoAddress) {
        usdcToken = IERC20(_usdcToken);
        i_daoAddress = _daoAddress;
    }

    function createCourse(
        uint256 _courseId,
        uint256 _price,
        uint256 _royaltyFee,
        uint256 _yieldRate,
        address _creator,
        string memory _uri
    ) external onlyOwner {
        require(!courses[_courseId].exists, "Course already exists");
        uint256 reward = _price * _yieldRate;
        courses[_courseId] = Course(
            _price,
            _royaltyFee,
            _yieldRate,
            reward,
            _creator,
            true,
            _uri
        );
        courseState = State.Closed;
        CoursePurchases[_courseId] = 0;
    }

    function createDegree(
        uint256 _degreeId,
        uint256 _price
    ) external onlyOwner {
        require(!degrees[_degreeId].exists, "Degree already exists");
        degrees[_degreeId] = Degree(new uint256[](0), _price, true);
        degreeState = State.Closed;
    }

    function addCourseToDegree(
        uint256 _degreeId,
        uint256 _courseId
    ) external onlyOwner {
        require(courses[_courseId].exists, "Course does not exist");
        require(degrees[_degreeId].exists, "Degree does not exist");

        degrees[_degreeId].courseIds.push(_courseId);
    }

    function deleteCourse(uint256 _courseId) external onlyOwner {
        require(courses[_courseId].exists, "Course does not exist");
        delete courses[_courseId];
    }

    function deleteDegree(uint256 _degreeId) external onlyOwner {
        require(degrees[_degreeId].exists, "Degree does not exist");
        delete degrees[_degreeId];
    }

    function updateCourse(
        uint256 _courseId,
        uint256 _price,
        uint256 _royaltyFee,
        uint256 _yieldRate,
        uint256 _completionReward,
        address _creator,
        string memory _uri
    ) external onlyOwner {
        require(courses[_courseId].exists, "Course does not exist");
        courses[_courseId].price = _price;
        courses[_courseId].royaltyFee = _royaltyFee;
        courses[_courseId].yieldRate = _yieldRate;
        courses[_courseId].completionReward = _completionReward;
        courses[_courseId].creator = _creator;
        courses[_courseId].uri = _uri;
    }

    function updateDegree(
        uint256 _degreeId,
        uint256 _price
    ) external onlyOwner {
        require(degrees[_degreeId].exists, "Degree does not exist");
        degrees[_degreeId].price = _price;
    }

    function purchaseCourse(uint256 _courseId) external nonReentrant {
        require(courses[_courseId].exists, "Course does not exist");
        require(
            usdcToken.transferFrom(
                msg.sender,
                i_daoAddress,
                courses[_courseId].price
            ),
            "Failed to transfer USDC tokens"
        );
        studentToCourseState[msg.sender][_courseId] = State.Open;
        CoursePurchases[_courseId] += 1;

        // mint and transfer nft to student
    }

    function purchaseDegree(uint256 _degreeId) external nonReentrant {
        require(degrees[_degreeId].exists, "Degree does not exist");
        require(
            usdcToken.transferFrom(
                msg.sender,
                i_daoAddress,
                degrees[_degreeId].price
            ),
            "Failed to transfer USDC tokens"
        );

        for (uint i = 0; i < degrees[_degreeId].courseIds.length; i++) {
            studentToCourseState[msg.sender][
                degrees[_degreeId].courseIds[i]
            ] = State.Open;
        }

        // mint and transfer nft to student
    }

    function completeCourse(uint256 _courseId) external nonReentrant {
        require(courses[_courseId].exists, "Course does not exist");
        require(
            i_daoAddress.balance >= courses[_courseId].completionReward,
            "Insufficient rewards balance"
        );

        studentBalances[msg.sender] += courses[_courseId].completionReward;
        studentToCourseState[msg.sender][_courseId] = State.Finished;
        CourseCompletions[_courseId] += 1;

        // call update token uri function in nft contract
        // call approve function in nft contract or call dao give rewards function in dao contract
        usdcToken.transferFrom(
            i_daoAddress,
            msg.sender,
            courses[_courseId].completionReward
        );
    }

    function completeDegree(uint256 _degreeId) external nonReentrant {
        require(degrees[_degreeId].exists, "Degree does not exist");
        for (uint256 i = 0; i < degrees[_degreeId].courseIds.length; i++) {
            require(
                studentToCourseState[msg.sender][
                    degrees[_degreeId].courseIds[i]
                ] == State.Finished,
                "You have not completed one of the courses in this specialization!"
            );
        }
        studentToDegreeState[msg.sender][_degreeId] = State.Finished;

        // require all courses in a degree have been completed - for loop and enum state
        // call update token uri function in nft contract
    }

    // function updateYieldRate(uint256 _courseId) external onlyOwner {
    //     require(courses[_courseId].exists, "Course does not exist");
    //     uint256 completionRate = (CourseCompletions[_courseId] / CoursePurchases[_courseId]);
    //     if (completionRate == 1) {
    //     courses[_courseId].yieldRate = 1 - courses[_courseId].royaltyFee;
    //     } else if (completionRate == .01) {
    //         courses[_courseId].yieldRate = 1.94;
    //     } else {
    //         courses[_courseId].yieldRate = .95 + (1 - completionRate);
    //     }
    // }
}

/*
  
    buy course - give royalties / mint and transfer nft 
    update state - when a course is completed and update nft uri
    Give rewards - set yield dynamically
    update nft uri using chainlink automation / Automating payouts using chainlink automation
    chainlinke keepers/ automation - updateYieldRate/ sending payouts from dao/ nft uri

*/

// Dao contract
// increase daoBalance on receive funciton in dao contract
// send royalties to teachers
