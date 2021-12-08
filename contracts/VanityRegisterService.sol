//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract VanityRegisterService is Ownable {
	struct VanityName {
        bytes name;
        uint256 expires;
        address owner;
    }

    struct LockedBalance {
		uint256 expires;
		uint256 lockedBalance;
	}

    uint256 public lockNamePrice = 0.01 ether;
    uint256 public lockTime = 90 days;
    uint256 public bytePrice = 0.0001 ether;
    uint256 public cumulFees = 0;
    uint8 public constant NAME_MIN_LENGTH = 3;
	uint8 public constant NAME_MAX_LENGTH = 50;
    uint16 public constant FRONTRUN_TIME = 3 minutes;

    mapping(bytes32 => VanityName) public vanityNames;
    mapping(bytes32 => uint256) public preRegisters;
    mapping(bytes32 => LockedBalance) public lockedBalances;

    modifier hasRequiredBalance(bytes memory _name) {
        uint256 namePrice = getNamePrice(_name);
        uint256 totalPrice = namePrice + lockNamePrice;
        require(msg.value >= totalPrice, "Insufficient amount!");
        _;
    }

    modifier isNameLengthAllowed(bytes memory _name) {
        require(_name.length >= NAME_MIN_LENGTH, "Name is too short.");
        require(_name.length <= NAME_MAX_LENGTH, "Name is too long.");
		_;
	}

    modifier hasPossiblePreRegister(bytes memory _name) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _name));
        require(preRegisters[hash] > 0, "No available preRegister.");
        require(block.timestamp > preRegisters[hash] + FRONTRUN_TIME, "No available preRegister.");
        _;
    }

    modifier isNameOwner(bytes memory name) {
		bytes32 nameHash = getNameHash(name);

		require(
			vanityNames[nameHash].owner == msg.sender &&
				vanityNames[nameHash].expires > block.timestamp,
			"No permission to name."
		);
		_;
	}

    modifier isAvailableName(bytes memory _name) {
        bytes32 nameHash = getNameHash(_name);
        require(
			vanityNames[nameHash].expires == 0 ||
				vanityNames[nameHash].expires < block.timestamp,
			"Name already registered."
		);
		_;
    }


    event VanityNameRegistered(bytes name, address owner, uint indexed timestamp);
    event VanityNameRenewed(bytes name, address owner, uint indexed timestamp);

    function preRegister(bytes32 _hash) external {
        preRegisters[_hash] = block.timestamp;
    }

    function register(bytes memory _name) 
        payable 
        isNameLengthAllowed(_name) 
        hasRequiredBalance(_name) 
        hasPossiblePreRegister(_name) 
        isAvailableName(_name)
        public {
        bytes32 nameHash = getNameHash(_name);
        VanityName memory newName = VanityName({
            name: _name,
            expires: block.timestamp + lockTime,
            owner: msg.sender
        });
    
        vanityNames[nameHash] = newName;
        cumulFees += getNamePrice(_name);

        bytes32 lbKey = keccak256(abi.encodePacked(msg.sender, _name));
        lockedBalances[lbKey] = LockedBalance({
            expires: block.timestamp + lockTime,
            lockedBalance: lockNamePrice
        });

        emit VanityNameRegistered(_name, msg.sender, block.timestamp);
    }

    function renew(bytes memory _name) public payable isNameOwner(_name) {
		bytes32 nameHash = getNameHash(_name);
		uint256 namePrice = getNamePrice(_name);
		require(msg.value == namePrice, "Invalid amount.");

		cumulFees += namePrice;
		vanityNames[nameHash].expires += lockTime;

        bytes32 lbKey = keccak256(abi.encodePacked(msg.sender, _name));
        lockedBalances[lbKey].expires += lockTime;
		
		emit VanityNameRenewed(_name, msg.sender, block.timestamp);
	}

    function withdrawLockedBalance(bytes memory _name) external {
        bytes32 lbKey = keccak256(abi.encodePacked(msg.sender, _name));

		require(lockedBalances[lbKey].lockedBalance > 0, "No locked balance");
		require(
			lockedBalances[lbKey].expires < block.timestamp,
			"Unable to unlock"
		);

		uint256 aux = lockedBalances[lbKey].lockedBalance;
		lockedBalances[lbKey].lockedBalance = 0;
		payable(msg.sender).transfer(aux);
    }

    function withdrawFees() external onlyOwner {
		require(cumulFees > 0, "No fees to withdraw");
		uint256 aux = cumulFees;
		cumulFees = 0;
		address _owner = owner();
		payable(_owner).transfer(aux);
	}
    
    function getRegisterPrice(bytes memory _name) external view isNameLengthAllowed(_name) returns (uint256) {
		uint256 namePrice = getNamePrice(_name);
		return namePrice + lockNamePrice;
	}

    function getNamePrice(bytes memory _name) public view isNameLengthAllowed(_name) returns (uint256) {
        return bytePrice * _name.length;
    }

    function getNameHash(bytes memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }

    function getPreRegisterHash(bytes memory _name) public view returns (bytes32) {
		return keccak256(abi.encodePacked(msg.sender, _name));
	}

    function setLockNamePrice(uint256 _price) external onlyOwner {
        lockNamePrice = _price;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }

    function setBytePrice(uint256 _bytePrice) external onlyOwner {
        bytePrice = _bytePrice;
    }

    function getNameOwner(bytes memory _name) public view returns (address) {
        bytes32 nameHash = getNameHash(_name);
        return vanityNames[nameHash].owner;
    }

    function isNameAvailable(bytes memory _name)
		external
		view
		isAvailableName(_name)
		isNameLengthAllowed(_name)
		returns (bool)
	{
		return true;
	}
}