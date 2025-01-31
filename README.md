# NanoTrade
A decentralized marketplace for nano-scale technology innovations built on Stacks blockchain.

## Overview
NanoTrade enables creators of nano-tech innovations to list and sell their intellectual property and products in a secure and transparent way. The platform supports:
- Listing of nano-tech innovations
- Secure transactions between buyers and sellers
- Escrow system for safe trading
- Ownership tracking via NFTs

## Contract Architecture
- `nano-marketplace.clar`: Main marketplace contract
  - Supports listing creation, purchases, and cancellations
  - Includes read-only function for querying listing details
  - Enhanced error handling for listing status
- `nano-token.clar`: SIP010-compliant token for transactions
- `nano-nft.clar`: NFT contract for ownership certificates

## Usage
[Documentation on how to use the contracts...]

### Recent Enhancements
- Added read-only function `get-listing` to query listing details
- Improved error handling for listing status validation
- Enhanced test coverage for marketplace functionality
