// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//IERC721 元数据接口，用于NFT的命名、设定符号和描述地址
interface IERC721Metadata {
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function tokenURI(uint256 tokenId) external view returns(string memory);
}