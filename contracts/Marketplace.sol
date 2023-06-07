// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./Vault.sol";
import "./SpecializationBadge.sol";

error Unauthorized();
error PriceNotMet(uint256 price);

//Use the AutomationCompatibleInterface from the library to ensure your checkUpkeep and performUpkeep 
//function definitions match the definitions expected by the Chainlink Automation Network.

//TODOS
// creating the functions needed to implement chainlink automation in order to update the token uri of the
// course badge as you progress through the course, and to automatically mint and transfer the two different nfts.
// One is the course badge that will be upgraded throughout the course as you make progress and the second is the
// Nft that is given upon completion of the course like a certificate

//create 3 JSON files for the nft metadata's one for each nft and one more for the nft badge after the uri has been
//updated. the metadata would be the same except for the asset used for the img

//also just go through the contracts and see if you can spot any major issues you dont have to write any test right
// now we have an auditor who will be doing that once we finish the contract. I did start to implement the chainlink
// functions in the marketplace contract
contract LearningPlatform is ReentrancyGuard, Ownable, ChainlinkClient, AutomationCompatibleInterface {
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

    mapping(uint256 => Course) public courses; // courseID to struct
    mapping(uint256 => Degree) public degrees; // degreeID to struct
    mapping(uint256 => string) public degreeURIs; // degreeId to nft URI
    mapping(address => uint256) public studentBalances;
    mapping(address => mapping(uint256 => State)) public studentToCourseState;
    mapping(address => mapping(uint256 => State)) public studentToDegreeState;
    mapping(uint256 => uint256) public CoursePurchases; // courseId => number of students
    mapping(uint256 => uint256) public CourseCompletions; // courseId => number of students

    IERC20 public usdcToken;
    State courseState;
    State degreeState;
    address payable public immutable i_vaultAddress;
    Vault public vault;
    SpecializationBadge public nft;

    // Chainlink variables
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor(
        address _usdcToken,
        address payable _vaultAddress,
        address _nft,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) {
        usdcToken = IERC20(_usdcToken);
        i_vaultAddress = _vaultAddress;
        vault = Vault(_vaultAddress);
        nft = SpecializationBadge(_nft);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = _fee;
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
        uint256 _price,
        string memory _uri
    ) external onlyOwner {
        require(!degrees[_degreeId].exists, "Degree already exists");
        degrees[_degreeId] = Degree(new uint256[](0), _price, true);
        degreeState = State.Closed;
        degreeURIs[_degreeId] = _uri;
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
        uint256 _price,
        string memory _uri,
        uint256[] _courseIds
    ) external onlyOwner {
        require(degrees[_degreeId].exists, "Degree does not exist");
        degrees[_degreeId].price = _price;
        degreeURIs[_degreeId] = _uri;
        degrees[_degreeId].courseIds = _courseIds;
    }

    function purchaseCourse(uint256 _courseId) external nonReentrant {
        uint256 price = courses[_courseId].price;
        uint256 royaltyFee = courses[_courseId].royaltyFee;
        address creator = courses[_courseId].creator;
        uint256 deposit = price - royaltyFee;
        uint256 royaltyAmount = (price * royaltyFee) / 100;

        require(courses[_courseId].exists, "Course does not exist");
        require(vault.depositToken(usdcToken, deposit), "Transaction Failed!");
        require(
            usdcToken.approve(creator, royaltyAmount),
            "Failed to approve transaction"
        );
        // Transfer the royalty fee to the course creator
        require(
            usdcToken.transferFrom(msg.sender, creator, royaltyAmount),
            "Failed to transfer royalty fee"
        );

        studentToCourseState[msg.sender][_courseId] = State.Open;
        CoursePurchases[_courseId] += 1;

        // mint and transfer nft to student
        nft.safeMint(msg.sender, courses[_courseId].uri);
    }

    function purchaseDegree(uint256 _degreeId) external nonReentrant {
        require(degrees[_degreeId].exists, "Degree does not exist");

        // Calculate the total price of the degree
        uint256 totalPrice = degrees[_degreeId].price;

        // Approve and transfer USDC tokens

        require(
            vault.depositToken(usdcToken, totalPrice),
            "Failed to transfer USDC tokens"
        );

        // Transfer the royalty fee to the course creators for each course in the degree
        for (uint256 i = 0; i < degrees[_degreeId].courseIds.length; i++) {
            uint256 courseId = degrees[_degreeId].courseIds[i];
            address creator = courses[courseId].creator;
            uint256 royaltyAmount = (totalPrice *
                courses[courseId].royaltyFee) /
                (degrees[_degreeId].courseIds.length);
            require(
                usdcToken.approve(creator, royaltyAmount),
                "Failed to approve transaction!"
            );
            require(
                usdcToken.transferFrom(msg.sender, creator, royaltyAmount),
                "Failed to transfer royalty fee"
            );

            studentToCourseState[msg.sender][courseId] = State.Open;
        }

        // mint and transfer nft to student
        nft.safeMint(msg.sender, degreeURIs[_degreeId]);
    }

    //This function should be called by chainlink's automation
    
    function completeCourse(uint256 _courseId) external nonReentrant {
        uint256 usdcAmount = vault.usdcAmount();
        require(courses[_courseId].exists, "Course does not exist");
        require(
            usdcAmount >= courses[_courseId].completionReward,
            "Insufficient rewards balance"
        );

        studentBalances[msg.sender] += courses[_courseId].completionReward;
        studentToCourseState[msg.sender][_courseId] = State.Finished;
        CourseCompletions[_courseId] += 1;

        // Call Chainlink to fetch the updated token URI
        requestUpdatedTokenURI(_courseId);

        bool success = vault.delegatecall(
            abi.encodeWithSignature(
                "withdrawUsdc(uint256, address)",
                usdcAmount >= courses[_courseId].completionReward,
                msg.sender
            )
        );

        require(success, "Transfer failed");
    }

    // automatically call this function with chainlink automation
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

        // call _mint function in certificate contract
    }

    function requestUpdatedTokenURI(uint256 _courseId) private {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillTokenURI.selector
        );
        req.add("courseId", uint2str(_courseId));
        req.add("url", "YOUR_EXTERNAL_ADAPTER_URL");

        // Set the desired Chainlink options
        req.add("copyPath", "YOUR_JSON_PATH");
        req.add("useHttpGet", "true");

        // Send the request
        sendChainlinkRequestTo(oracle, req, fee);
    }

    function fulfillTokenURI(
        bytes32 _requestId,
        string memory _tokenURI
    ) public recordChainlinkFulfillment(_requestId) {
        // Update the token URI for the completed course
        uint256 courseId = parseInt(_tokenURI);
        nft.updateTokenURI(courseId, courses[courseId].uri);
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
// give access to this contract to send money to and from vault
