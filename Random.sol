// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC721.sol";
import "@chainlink/contract/scr/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

//旧版V1
contract Random is ERC721, VRFConsumerBaseV2 {
    uint256 public totalSupply = 100;
    uint256[100] public ids;
    uint256 public mintCount;

    VRFCoordinatorV2Interface COORDINATOR;

    address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint64 subId;
    uint256 public requestId;

    mapping(uint256 => address) public requestToSender;

    constructor(
        uint64 s_subId
    ) VRFConsumerBaseV2(vrfCoordinator) ERC721("ETH Random", "ETH") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subId = s_subId;
    }

    function pickRandomUniqueId(
        uint256 random
    ) private returns (uint256 tokenId) {
        uint256 len = totalSupply - mintCount++;
        require(len > 0, "mint close");
        uint256 randomIndex = random % len;

        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1];
        ids[len - 1] = 0;
    }

    function getRandomOnchain() public view returns (uint256) {
        bytes32 randomBytes = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                block.timestamp
            )
        );
        return uint256(randomBytes);
    }

    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain());
        _mint(msg.sender, _tokenId);
    }

    function mintRandomVRF() public {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestToSender[requestId] = msg.sender;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory s_randomWords
    ) internal override {
        address sender = requestToSender[requestId];
        uint256 tokenId = pickRandomUniqueId(s_randomWords[0]);
        _mint(sender, tokenId);
    }
}
