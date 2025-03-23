// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract RandomNumberConsumer2 is VRFConsumerBaseV2Plus {
    uint256 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 constant CALLBACK_GAS_LIMIT = 100000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;

    // bytes32 public keyHash =
    //     0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    // address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;

    event ReturnedRandomness(uint256[] randomWords);

    constructor(
        uint256 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
    }

    // constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
    //     s_subscriptionId = subscriptionId;
    // }

    function requestRandomWords() external onlyOwner {
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        s_randomWords = randomWords;
        emit ReturnedRandomness(randomWords);
    }
}
