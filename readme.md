# P2P Swap Desk

**An onchain peer-to-peer token swap market with smart-contract escrow and atomic settlement.**

Built for **Problem Statement 02: Onchain Finance & Trading**.
Status: **working prototype on the Sepolia testnet** (unaudited, mock tokens, no real funds).

> Team: [your team name]  
> Members: [names]  
> Demo video: [link]  
> Repository: [GitHub link]

---

## 1. One-line pitch

Post an order, lock your tokens in a smart contract, and let anyone fill it. Both sides swap in a single transaction, and no company ever holds your funds.

---

## 2. The problem

Most peer-to-peer trading today runs through a platform that sits in the middle.

| Pain point | What happens today |
|---|---|
| Opaque order books | Orders, fills and fees live in a private database that users cannot audit. |
| Custodial escrow | The platform holds funds during a trade, so users carry counterparty risk. |
| Slow, manual disputes | Support staff decide outcomes, and the rules are not verifiable by users. |
| Delayed settlement | Trades settle in batches, not at the moment both sides agree. |

**Problem Statement 02 asks for:**
> A fully onchain financial product that leverages fast blockchain settlement to create innovative and transparent trading or lending markets without relying on centralized offchain infrastructure.

---

## 3. Our solution

P2P Swap Desk replaces the middleman with a smart contract.

1. **A maker posts an order.** For example: "I sell 10 USDC and want 10 LOCAL." The contract pulls the maker's 10 USDC into escrow.
2. **The order is public.** Anyone can read it directly from the blockchain.
3. **A taker fills the order.** In one transaction, the contract sends the taker's LOCAL to the maker and releases the locked USDC to the taker.
4. **Or the maker cancels.** The locked tokens return to the maker. After an order expires, anyone can trigger the refund to the maker.

**Key properties**

- **No custodian.** Funds sit in contract code, not in a company's account.
- **Atomic settlement.** Either both transfers happen or neither does. Nobody is left holding half a trade.
- **Public audit trail.** Every order, fill and cancellation emits an event anyone can verify.
- **Rule-based expiry.** Each order has a deadline set by the maker, enforced by the contract.

---

## 4. How it works (user flow)

```
Maker                     Smart contract (P2PMarket)                 Taker
  |                                  |                                 |
  | 1. approve(USDC -> market)       |                                 |
  | 2. createOrder(sell 10 USDC,     |                                 |
  |    want 10 LOCAL, 1 hour) ------>| locks 10 USDC in escrow         |
  |                                  | emits Created(id=0, ...)        |
  |                                  |                                 |
  |                                  |<------ 3. approve(LOCAL -> market)
  |                                  |<------ 4. fillOrder(0)          |
  |<-- 10 LOCAL (from taker) --------| swaps both sides atomically ----|--> 10 USDC (from escrow)
  |                                  | emits Filled(id=0, taker)       |
```

**Why there is an `approve` step.** Token contracts require explicit permission before another contract can move your tokens. The web app handles this automatically: if the market has no permission yet, it asks for an approval first, then posts the order or fills it.

---

## 5. Deployed contracts (Sepolia testnet)

| Contract | Role | Address |
|---|---|---|
| **P2PMarket** | Escrow and order market | [`0x1deE77D95152A0BEAeA6Ed082DA888c471d9eC38`](https://sepolia.etherscan.io/address/0x1deE77D95152A0BEAeA6Ed082DA888c471d9eC38) |
| **USDC (mock)** | Test token with a public faucet | [`0xf6BcE665263e9bF90b60cF923327A22058727ebD`](https://sepolia.etherscan.io/address/0xf6BcE665263e9bF90b60cF923327A22058727ebD) |
| **LOCAL (mock)** | Second test token with a public faucet | [`0x4dbcED9371049eF8Cb71F7335B14205e2BF45B51`](https://sepolia.etherscan.io/address/0x4dbcED9371049eF8Cb71F7335B14205e2BF45B51) |

- **Network:** Ethereum Sepolia testnet (chain ID `11155111`)
- **Tokens are mock tokens.** Anyone can mint 1000 test tokens by calling `faucet()`. They have no real value.

### Proof of a completed swap

- Order creation transaction: [Etherscan link]
- Order fill transaction: [Etherscan link]
- Screenshots: `screenshots/` folder (order posted, order filled, balances before and after, Etherscan event logs)

---

## 6. Architecture

```
┌─────────────────────────┐
│   Web app (index.html)  │  Static page: HTML, CSS, JavaScript, ethers.js
│   Connect wallet, post  │  No backend server, no database
│   orders, fill, cancel  │
└───────────┬─────────────┘
            │ signs transactions with the user's wallet (MetaMask)
            ▼
┌─────────────────────────┐
│  Smart contracts        │  P2PMarket (escrow + order book + settlement)
│  (Solidity 0.8.x)       │  MockToken x2 (USDC and LOCAL for testing)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│  Ethereum Sepolia       │  State, events and finality live here
└─────────────────────────┘
```

**Design principles**

- All trading logic and state live in the contract.
- The web app only reads chain state and sends signed transactions.
- The app has no server and no database. Order status is rebuilt from contract storage and public events.
- Users keep custody of their keys at all times.

---

## 7. Technology stack

| Layer | Technology |
|---|---|
| Smart contracts | Solidity (^0.8.20) |
| Contract libraries | OpenZeppelin (ERC20, SafeERC20) |
| Development and deployment | Remix IDE |
| Wallet | MetaMask |
| Blockchain | Ethereum Sepolia testnet |
| Frontend | HTML, CSS, JavaScript |
| Wallet and chain library | ethers.js v6 |
| Block explorer | Sepolia Etherscan |

---

## 8. Smart contract reference

### `P2PMarket`

**Order structure**

| Field | Meaning |
|---|---|
| `maker` | Address that created the order |
| `sellToken`, `sellAmount` | Token and amount the maker locks |
| `buyToken`, `buyAmount` | Token and amount the maker wants in return |
| `expiry` | Deadline (Unix timestamp) |
| `open` | `true` while the order can still be filled or cancelled |

**Functions**

| Function | What it does |
|---|---|
| `createOrder(sellToken, sellAmount, buyToken, buyAmount, duration)` | Locks the maker's `sellAmount` in escrow and records a new order. Returns the order id. |
| `fillOrder(id)` | Must be called before expiry on an open order. Sends the taker's `buyAmount` to the maker and releases the escrowed `sellAmount` to the taker, in one transaction. |
| `cancelOrder(id)` | Returns the escrowed tokens to the maker. The maker can cancel any time while the order is open. After expiry, anyone can call it to trigger the refund to the maker. |
| `orderCount()` | Returns how many orders exist. |
| `orders(id)` | Returns the full details of an order. |

**Events (public audit trail)**

| Event | Emitted when |
|---|---|
| `Created(id, maker, sellToken, sellAmount, buyToken, buyAmount, expiry)` | An order is posted |
| `Filled(id, taker)` | An order is filled |
| `Cancelled(id)` | An order is cancelled or refunded |

**Safety measures in the code**

- Uses OpenZeppelin `SafeERC20` for all token transfers.
- Marks an order closed **before** moving tokens, which blocks reuse and re-entrancy on the same order.
- Rejects zero amounts, expired orders and already-closed orders.

### `MockToken`

A standard ERC20 token with a public `faucet()` that mints 1000 tokens (18 decimals) to the caller. Used for testing only.

---

## 9. The web app

A single file, `index.html`, that talks directly to the contracts through the user's wallet.

**Features**

- Connect a MetaMask wallet and switch to Sepolia automatically.
- View your USDC and LOCAL balances, with one-click free test tokens.
- **Post an order:** choose the tokens, amounts and how long it stays open. The app requests the needed approval first.
- **Order book:** every order read from the chain, with status (Open, Filled, Cancelled, Expired), rate, maker and expiry.
- **Fill an order** posted by someone else, or **cancel** your own.
- Live status bar with a link to each transaction on Etherscan.
- Automatic refresh every few seconds and after every transaction.
- Plain-language error messages (for example, "Not enough tokens").

---

## 10. Run it yourself

### Prerequisites

- A desktop browser (Chrome recommended)
- [MetaMask](https://metamask.io) with two accounts (call them Maker and Taker)
- Sepolia test ETH in both accounts for gas fees (free from a Sepolia faucet)
- VS Code with the Live Server extension (or any static file server)

### Steps

1. Clone this repository.
2. Open the folder in VS Code, right-click `index.html`, and choose **Open with Live Server**.
3. Click **Connect wallet** and approve the connection. Switch to Sepolia if asked.
4. As **Maker**: click **Get 1000 free USDC**, then post an order, for example sell 10 USDC for 10 LOCAL.
5. Switch to the **Taker** account in MetaMask. The page reloads.
6. As **Taker**: click **Get 1000 free LOCAL**, then click **Fill order** on the open order.
7. Check both balances. The Maker now holds LOCAL and the Taker holds USDC.

### Deploy your own copy

1. Open [Remix](https://remix.ethereum.org) and create `Market.sol` with the contract source (see Appendix).
2. Compile with Solidity 0.8.20 or newer.
3. Set the environment to **Injected Provider - MetaMask** on Sepolia.
4. Deploy `MockToken` twice (`USDC`/`USDC` and `LOCAL`/`LOCAL`), then deploy `P2PMarket`.
5. Replace the three addresses in the configuration block at the top of the script in `index.html`.

---

## 11. How this fits Problem Statement 02

| PS 02 requirement | How we address it |
|---|---|
| Fully onchain financial product | Orders, escrow, matching and settlement all execute in a smart contract. |
| Fast blockchain settlement | A fill settles both sides in one transaction, in seconds. |
| Transparent trading market | Order state is public, and every action emits an event on the chain. |
| Without centralized offchain infrastructure | There is no backend server and no database. The app reads and writes the chain directly. |

**What we are honest about**

- The web page is a static file that has to be hosted somewhere. It is a convenience client. Anyone can use the contract without it, for example through Etherscan or their own interface.
- The app reads the chain through the user's wallet connection, which relies on an RPC provider.
- This is a **token-for-token** market. Moving between real money and tokens (on-ramps and off-ramps) would sit outside the contract and is not part of this prototype.

---

## 12. Testing performed

Manual end-to-end tests on the Remix VM and on Sepolia:

- Faucet mints test tokens to a wallet.
- Posting an order without an approval fails with an allowance error, as expected.
- Posting an order without enough balance fails with a balance error, as expected.
- A correct order locks the maker's tokens, and `orderCount` increases.
- A second wallet fills the order and both balances change correctly.
- Cancelling an open order returns the tokens to the maker.

**Not yet done:** automated test suites, fuzz testing, formal verification and an independent audit.

---

## 13. Limitations and risks

We want to be clear about what this prototype is and is not.

| Area | Limitation |
|---|---|
| Security | The contracts are **unaudited**. Do not use them with real funds. |
| Tokens | Uses mock tokens with a public faucet. Tokens that charge fees on transfer or behave unusually are not supported. |
| Order types | Orders are all-or-nothing. There are no partial fills. |
| Pricing | The maker sets the price. There is no price oracle or matching engine. |
| Liquidity | A new market starts with an empty order book. |
| Fees | No protocol fee yet. |
| Scale | Orders are stored in an array that the app reads in full, which will not scale to a large market without an indexer. |
| History | The app labels Filled and Cancelled orders using events from roughly the last 45,000 blocks. Older orders show as Closed. |
| Compliance | Real-money use would require legal review of KYC/AML rules for each country. |

---

## 14. Roadmap

**Now (hackathon submission)**

- Working escrow and atomic swap on Sepolia
- Web app with wallet connection, order book, fill and cancel
- Public proof on Etherscan

**Next (weeks)**

- Verify the contract source on Etherscan
- Partial fills
- A transparent protocol fee written in the contract
- Automated tests with Foundry or Hardhat
- Better order book: sorting by rate and filtering by token pair

**Later (months)**

- Independent security audit
- A lending pool as a second market
- Deployment to a low-cost chain such as Base or Arbitrum for a pilot
- Real stablecoins in place of mock tokens
- Legal and compliance review before any real-money launch

---



