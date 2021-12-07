//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VanityRegisterService is Ownable {
	struct VanityName {
        bytes name;
        uint256 expires;
        address owner;
    }

    uint256 public lockNamePrice = 0.01 ether;
    uint256 public lockTime = 90 days;
    uint256 public bytePrice = 0.0001 ether;
    uint8 public constant NAME_MIN_LENGTH = 3;
	uint8 public constant NAME_MAX_LENGTH = 50;
    uint16 public constant FRONTRUN_TIME = 3 minutes;

    mapping(bytes32 => VanityName) public vanityNames;
    mapping(bytes32 => uint256) public preRegisters;

    modifier isNameLengthAllowed(bytes memory _name) {
		// @dev - check if the provided name is with allowed length
		require(_name.length >= NAME_MIN_LENGTH, "Name is too short.");
		require(_name.length <= NAME_MAX_LENGTH, "Name is too long.");
		_;
	}

    modifier hasRequiredBalance(bytes memory _name) {
        uint256 namePrice = getNamePrice(_name);
        uint256 totalPrice = namePrice + lockNamePrice;
        require(msg.value > totalPrice, "Insufficient amount!");
        _;
    }

    modifier hasPossiblePreRegister(bytes memory _name) {
        bytes32 hash = keccak256(abi.encodePacked(_name, msg.sender));
        require(preRegisters[hash] > 0, "Has no available preRegister");
        require(block.timestamp > preRegisters[hash] + FRONTRUN_TIME, "Should wait for a while...");
        _;
    }

    event VanityNameRegistered(bytes name, address owner, uint indexed timestamp);

    function preRegister(bytes32 _hash) external {
        preRegisters[_hash] = block.timestamp;
    }

    function register(bytes memory _name) payable isNameLengthAllowed(_name) hasRequiredBalance(_name) hasPossiblePreRegister(_name) public {
        bytes32 nameHash = getNameHash(_name);
        VanityName memory newName = VanityName({
            name: _name,
            expires: block.timestamp + lockTime,
            owner: msg.sender
        });
    
        vanityNames[nameHash] = newName;
        emit VanityNameRegistered(_name, msg.sender, block.timestamp);
    }

    function getNamePrice(bytes memory _name) public view isNameLengthAllowed(_name) returns (uint256) {
        return bytePrice * _name.length;
    }

    function getNameHash(bytes memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}