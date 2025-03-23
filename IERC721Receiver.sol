// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//（ERC721接收者接口）
interface IERC721Receiver{

    //安全转账接口
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}