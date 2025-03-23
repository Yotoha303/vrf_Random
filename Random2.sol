// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC721.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Random2 is ERC721, VRFConsumerBaseV2Plus {
    uint256 public totalSupply = 100;
    uint256[100] public ids;
    uint256 public mintCount;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint256 => address) public requestToSender;

    uint256 public s_subscriptionsId;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 public keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 public callbackGasLimit = 100000;

    uint16 public requestConfirmations = 3;
    uint32 public numWords = 2;

    address COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;

    constructor(
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(COORDINATOR) ERC721("ETH Random", "ETH") {
        s_subscriptionsId = subscriptionId;
    }

    //请求随机数
    function requestRandomWords() public {
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionsId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;

        //存储随机数提供者的信息
        requestToSender[requestId] = msg.sender;

        emit RequestSent(requestId, numWords);
    }

    /** 
    * 输入uint256数字，返回一个可以mint的tokenId
    * 算法过程可理解为：totalSupply个空杯子（0初始化的ids）排成一排，每个杯子旁边放一个球，编号为[0, totalSupply - 1]。
      每次从场上随机拿走一个球（球可能在杯子旁边，这是初始状态；也可能是在杯子里，说明杯子旁边的球已经被拿走过，则此时新的球从末尾被放到了杯子里）
      再把末尾的一个球（依然是可能在杯子里也可能在杯子旁边）放进被拿走的球的杯子里，循环totalSupply次。相比传统的随机排列，省去了初始化ids[]的gas。
    */
    function pickRandomUniqueId(
        uint256 random
    ) private returns (uint256 tokenId) {
        uint256 len = totalSupply - mintCount++;    //可以铸造的tokenId数量
        require(len > 0, "mint close");
        uint256 randomIndex = random % len;     //获取链上随机数

        //随机数取模，得到tokenId，作为数组下标，同时记录value为len-1，如果取模得到的值已存在，则tokenId取该数组下标的value
        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1];
        ids[len - 1] = 0;
    }

    //铸造NFT
    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain());
        _mint(msg.sender, _tokenId);
    }

    //将当前链上的随机数信息进行打包
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

    function fulfillRandomWords(
        uint256 _requestsId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestsId].exists, "request not found");
        s_requests[_requestsId].fulfilled = true;
        s_requests[_requestsId].randomWords = _randomWords;

        //获取提供者
        address sender = requestToSender[_requestsId];

        uint256 tokenId = pickRandomUniqueId(_randomWords[0]);
        _mint(sender, tokenId);

        emit RequestFulfilled(_requestsId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestsId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestsId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestsId];
        return (request.fulfilled, request.randomWords);
    }
}
