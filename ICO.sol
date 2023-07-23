// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FundToken.sol";

contract ICO{
    
    uint256 public constant ICOGoal = 30000000 ether;

    uint256 public constant SeedPhaseSaleLimit = 15000000 ether;
    uint256 public constant SeedPhaseIndividualLimit = 1500000 ether;

    uint256 public constant GeneralPhaseSaleLimit = 15000000 ether;
    uint256 public constant GeneralPhaseIndividualLimit = 500000 ether;

    address public immutable Owner;
    address public immutable TokenAddress;

    uint256 public currentTotalContribution;
    bool public isFundraisingAndFDTRedemptionPaused = false;
    Phase public currentPhase = Phase.Seed;

    mapping(address => bool) public isPrivateContributor;
    mapping(address => uint256) public tokenReedemed;
    mapping(address => uint256) public contributions;
    

    event FundraisingAndFDTRedemptionPaused();
    event FundRaisingAndFDTRedemptionResumed();
    event PhaseChanged(uint8 newPhase);
    event PrivateContributorsAdded(address[] contributors);
    event TokenRedeemed(address indexed to, uint256 amount);
    event ContributionsMade(uint8 indexed currentPhase, address indexed contributor, uint256 value);

     modifier onlyOwner() {
        require(msg.sender == Owner, "only owner allowed");
        _;
    }

    modifier isFundRaisingAndFDTRedemptionActive() {
        require(
            !isFundraisingAndFDTRedemptionPaused, "fund raising and FDT token redemption is paused");
        _;
    }

    enum Phase {
        Seed,
        General
    }

    constructor(address treasury) {
        Owner = msg.sender;
        FundToken fundCoin = new FundToken(Owner, treasury, address(this));
        TokenAddress = address(fundCoin);
    }

     function pauseFundraisingAndFDTRedemption()
        external
        onlyOwner
        isFundRaisingAndFDTRedemptionActive
    {
        isFundraisingAndFDTRedemptionPaused = true;
        emit FundraisingAndFDTRedemptionPaused();
    }

    function resumeFundraisingAndFDTRedemption() external onlyOwner {
        require(
            isFundraisingAndFDTRedemptionPaused,
            "fund raising and spc redemption is active"
        );
        isFundraisingAndFDTRedemptionPaused = false;
        emit FundRaisingAndFDTRedemptionResumed();
    }

    function updatePhase(uint8 newPhase) external onlyOwner {
        require(currentPhase != Phase.General, "can't advance phase after General");
        require(newPhase <= uint8(Phase.General), "invalid phase");
        require(
            uint8(currentPhase) != newPhase,
            "current phase is same as desired phase"
        );
        if (currentPhase == Phase.Seed) {
            require(
                newPhase == uint8(Phase.General),
                "can only move from Seed to General"
            );
            currentPhase = Phase.General;
        } 
        
        emit PhaseChanged(uint8(currentPhase));
    }

    function addPrivateContributors(address[] calldata contributors)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < contributors.length; i++) {
            isPrivateContributor[contributors[i]] = true;
        }
        emit PrivateContributorsAdded(contributors);
    }




    function participateInICO() external payable isFundRaisingAndFDTRedemptionActive {
        require(msg.value > 0, "no contributions made");

        if (currentPhase == Phase.Seed) {
            require(isPrivateContributor[msg.sender], "not a private investor");
            require(
                currentTotalContribution + msg.value <=
                    SeedPhaseSaleLimit,
                "seed phase - total contribution limit exceeded"
            );
            require(
                contributions[msg.sender] + msg.value <=
                    SeedPhaseIndividualLimit,
                "seed phase - individual contribution limit exceeded"
            );
            currentTotalContribution += msg.value;
            contributions[msg.sender] += msg.value;
            emit ContributionsMade(uint8(Phase.Seed), msg.sender, msg.value);
        } else if (currentPhase == Phase.General) {
            require(
                currentTotalContribution + msg.value <=
                    GeneralPhaseSaleLimit,
                "general phase - total contribution limit exceeded"
            );
            require(
                contributions[msg.sender] + msg.value <=
                    GeneralPhaseIndividualLimit,
                "general phase - individual contribution limit exceeded"
            );

            currentTotalContribution += msg.value;
            contributions[msg.sender] += msg.value;
            emit ContributionsMade(uint8(Phase.General), msg.sender, msg.value);
        } 
    }


    function redeemToken() external isFundRaisingAndFDTRedemptionActive {
        require(
            currentPhase == Phase.General,
            "can redeem only during General phase"
        );
        require(contributions[msg.sender] > 0, "no contributions made");
        uint256 amountToTransfer = (contributions[msg.sender] * 5) -
            tokenReedemed[msg.sender];
        if (amountToTransfer > 0) {
            tokenReedemed[msg.sender] += amountToTransfer;
            FundToken fundCoin = FundToken(TokenAddress);
            fundCoin.transfer(msg.sender, amountToTransfer);
            emit TokenRedeemed(msg.sender, amountToTransfer);
        }
    }


}
