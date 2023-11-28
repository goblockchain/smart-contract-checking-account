/**
 * This file is autogenerated by Scaffold-ETH.
 * You should not edit it manually or your changes might be overwritten.
 */
import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

const deployedContracts = {
  80001: {
    Factory: {
      address: "0xA48444C6035Afc7b51f865db621fFcE98ed8495F",
      abi: [
        {
          inputs: [
            {
              internalType: "address",
              name: "_firstUser",
              type: "address",
            },
            {
              internalType: "string",
              name: "_firstUserName",
              type: "string",
            },
          ],
          stateMutability: "nonpayable",
          type: "constructor",
        },
        {
          inputs: [],
          name: "ArrayLengthMismatch",
          type: "error",
        },
        {
          inputs: [],
          name: "ForbiddenSender",
          type: "error",
        },
        {
          inputs: [],
          name: "InvalidCalldata",
          type: "error",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "token",
              type: "address",
            },
          ],
          name: "InvalidToken",
          type: "error",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "user",
              type: "address",
            },
          ],
          name: "InvalidUser",
          type: "error",
        },
        {
          inputs: [],
          name: "Locked",
          type: "error",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "nonUser",
              type: "address",
            },
          ],
          name: "NotAUser",
          type: "error",
        },
        {
          inputs: [],
          name: "UnableToMove",
          type: "error",
        },
        {
          anonymous: false,
          inputs: [
            {
              indexed: false,
              internalType: "address",
              name: "user",
              type: "address",
            },
            {
              indexed: false,
              internalType: "address",
              name: "smartAccount",
              type: "address",
            },
            {
              indexed: false,
              internalType: "int256",
              name: "change",
              type: "int256",
            },
            {
              indexed: false,
              internalType: "int256",
              name: "credit",
              type: "int256",
            },
          ],
          name: "CreditUpdated",
          type: "event",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "_admin",
              type: "address",
            },
          ],
          name: "addAdmin",
          outputs: [
            {
              internalType: "address[]",
              name: "newAdmins",
              type: "address[]",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "admin",
              type: "address",
            },
          ],
          name: "admin",
          outputs: [
            {
              internalType: "bool",
              name: "",
              type: "bool",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "uint256",
              name: "",
              type: "uint256",
            },
          ],
          name: "admins",
          outputs: [
            {
              internalType: "address",
              name: "",
              type: "address",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address[]",
              name: "users",
              type: "address[]",
            },
            {
              internalType: "address[]",
              name: "_newSmartAccounts",
              type: "address[]",
            },
          ],
          name: "batchSetSmartAccounts",
          outputs: [
            {
              internalType: "bool",
              name: "",
              type: "bool",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address[]",
              name: "users",
              type: "address[]",
            },
            {
              internalType: "int256[]",
              name: "_liabilities",
              type: "int256[]",
            },
          ],
          name: "batchUpdate",
          outputs: [],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "_user",
              type: "address",
            },
            {
              internalType: "string",
              name: "_username",
              type: "string",
            },
          ],
          name: "create",
          outputs: [
            {
              internalType: "address",
              name: "user",
              type: "address",
            },
            {
              internalType: "address",
              name: "smartAccount",
              type: "address",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address[]",
              name: "users",
              type: "address[]",
            },
          ],
          name: "credits",
          outputs: [
            {
              internalType: "int256[]",
              name: "",
              type: "int256[]",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "uint256",
              name: "userId",
              type: "uint256",
            },
            {
              internalType: "bool",
              name: "refund",
              type: "bool",
            },
          ],
          name: "deactivate",
          outputs: [
            {
              internalType: "bool",
              name: "",
              type: "bool",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "_token",
              type: "address",
            },
            {
              internalType: "address",
              name: "_to",
              type: "address",
            },
            {
              internalType: "uint256",
              name: "_id",
              type: "uint256",
            },
          ],
          name: "move",
          outputs: [
            {
              internalType: "bool",
              name: "",
              type: "bool",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "operator",
              type: "address",
            },
            {
              internalType: "address",
              name: "from",
              type: "address",
            },
            {
              internalType: "uint256[]",
              name: "ids",
              type: "uint256[]",
            },
            {
              internalType: "uint256[]",
              name: "values",
              type: "uint256[]",
            },
            {
              internalType: "bytes",
              name: "data",
              type: "bytes",
            },
          ],
          name: "onERC1155BatchReceived",
          outputs: [
            {
              internalType: "bytes4",
              name: "",
              type: "bytes4",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "operator",
              type: "address",
            },
            {
              internalType: "address",
              name: "from",
              type: "address",
            },
            {
              internalType: "uint256",
              name: "id",
              type: "uint256",
            },
            {
              internalType: "uint256",
              name: "value",
              type: "uint256",
            },
            {
              internalType: "bytes",
              name: "data",
              type: "bytes",
            },
          ],
          name: "onERC1155Received",
          outputs: [
            {
              internalType: "bytes4",
              name: "",
              type: "bytes4",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "operator",
              type: "address",
            },
            {
              internalType: "address",
              name: "from",
              type: "address",
            },
            {
              internalType: "uint256",
              name: "tokenId",
              type: "uint256",
            },
            {
              internalType: "bytes",
              name: "data",
              type: "bytes",
            },
          ],
          name: "onERC721Received",
          outputs: [
            {
              internalType: "bytes4",
              name: "",
              type: "bytes4",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "uint256[]",
              name: "usersIds",
              type: "uint256[]",
            },
            {
              internalType: "int256",
              name: "amounts",
              type: "int256",
            },
          ],
          name: "punish",
          outputs: [],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "string",
              name: "userName",
              type: "string",
            },
          ],
          name: "registerSelf",
          outputs: [
            {
              internalType: "address",
              name: "smartUserAccount",
              type: "address",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "_admin",
              type: "address",
            },
          ],
          name: "removeAdmin",
          outputs: [
            {
              internalType: "address[]",
              name: "newAdmins",
              type: "address[]",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address[]",
              name: "users",
              type: "address[]",
            },
          ],
          name: "scores",
          outputs: [
            {
              internalType: "int256[]",
              name: "scores",
              type: "int256[]",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "uint256",
              name: "userId",
              type: "uint256",
            },
            {
              internalType: "uint256",
              name: "minAllocation",
              type: "uint256",
            },
          ],
          name: "setMinAllocation",
          outputs: [
            {
              internalType: "uint256",
              name: "newMinAllocation",
              type: "uint256",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "paymentTokens",
              type: "address",
            },
            {
              internalType: "uint256",
              name: "tokenType",
              type: "uint256",
            },
          ],
          name: "setPaymentTokens",
          outputs: [
            {
              internalType: "address[]",
              name: "newPaymentTokens",
              type: "address[]",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "uint256",
              name: "percentageFromAllocation",
              type: "uint256",
            },
          ],
          name: "setPercentageFromAllocation",
          outputs: [
            {
              internalType: "uint256",
              name: "newPercentageFromAllocation",
              type: "uint256",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "tokenAddress",
              type: "address",
            },
          ],
          name: "setPermittedERC1155Tokens",
          outputs: [
            {
              internalType: "address[]",
              name: "",
              type: "address[]",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "tokenAddress",
              type: "address",
            },
          ],
          name: "setPermittedERC20Tokens",
          outputs: [
            {
              internalType: "address[]",
              name: "newPermittedERC20Tokens",
              type: "address[]",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "tokenAddress",
              type: "address",
            },
          ],
          name: "setPermittedERC721Tokens",
          outputs: [
            {
              internalType: "address[]",
              name: "newPermittedERC721Tokens",
              type: "address[]",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "user",
              type: "address",
            },
            {
              internalType: "address",
              name: "newSmartAccount",
              type: "address",
            },
          ],
          name: "setSmartAccount",
          outputs: [
            {
              internalType: "bool",
              name: "",
              type: "bool",
            },
          ],
          stateMutability: "nonpayable",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "user",
              type: "address",
            },
          ],
          name: "smartAccount",
          outputs: [
            {
              internalType: "address",
              name: "",
              type: "address",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "bytes4",
              name: "interfaceId",
              type: "bytes4",
            },
          ],
          name: "supportsInterface",
          outputs: [
            {
              internalType: "bool",
              name: "",
              type: "bool",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "token",
              type: "address",
            },
          ],
          name: "tokenToStandard",
          outputs: [
            {
              internalType: "uint256",
              name: "",
              type: "uint256",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          inputs: [
            {
              internalType: "address",
              name: "user",
              type: "address",
            },
          ],
          name: "user",
          outputs: [
            {
              internalType: "bool",
              name: "",
              type: "bool",
            },
          ],
          stateMutability: "view",
          type: "function",
        },
        {
          stateMutability: "payable",
          type: "receive",
        },
      ],
      inheritedFunctions: {},
    },
  },
} as const;

export default deployedContracts satisfies GenericContractsDeclaration;