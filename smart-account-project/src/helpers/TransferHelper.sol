pragma solidity ^0.8.13;

/**
 * @notice helper methods for interacting with ETH/ERC721/ERC1155 tokens and sending ERC20s that do not consistently return true/false.
 * @dev inspired in the UniswapV2 TransferHelper library.
 */

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    /**
     * @notice safeTransfer ERC20 tokens.
     */
    function safeTransfer(address token, address to, uint256 value) internal {
        /// @dev bytes4(keccak256(bytes('transfer(address,uint256)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    /**
     * @notice safeTransferFrom ERC20 tokens.
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        /// @dev bytes4(keccak256(bytes('transferFrom(address,address,uint256)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    /**
     * @notice safeTransfer ERC721 tokens.
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint id
    ) internal {
        ///@dev bytes4(keccak256('bytes(safeTransferFrom(address from, address to, uint256 tokenId))'))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x42842e0e, from, to, id)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    /**
     * @notice safeTransfer ERC1155 tokens.
     */
    function safeTransferERC1155From(
        address token,
        address from,
        address to,
        uint id,
        uint256 value
    ) internal {
        /// @dev bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xf242432a, from, to, id, value, "0x")
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    /**
     * @notice safeTransfer ETH.
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}
