%lang starknet

// The buffer to take into account current block time = 2 hours

const BLOCK_TIME_BUFFER = 2 * 3600;

// The minimum increment between two bids (ETH has 18 decimals)

const BID_INCREMENT = 5000000000000000;  // 0.005 ETH = 6.5$

// The max length for the theme (in # of felts)

const THEME_MAX_LENGTH = 5;
