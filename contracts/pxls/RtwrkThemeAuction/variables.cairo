%lang starknet

// The buffer to take into account current block time = 2 hours

const BLOCK_TIME_BUFFER = 2 * 3600;

// The max length for the theme

const THEME_MAX_LENGTH = 5 * 31; // 5 felts

// The divisor of total bid amount that goes to the project (1/10)

const PXLS_BID_AMOUNT_DIVISOR = 10;
