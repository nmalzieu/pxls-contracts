%lang starknet

// Since making our contract upgradeable for Regenesis,
// we don't need to store variables / settings in storage
// and add getters and setters, we can just modify this
// file and upgrade implementation.


// For performance limit to reconstitute grid

const MAX_PIXEL_COLORIZATIONS_PER_COLORIZER = 20;
const MAX_TOTAL_PIXEL_COLORIZATIONS = 2000;

// The buffer to take into account current block time = 2 hours

const BLOCK_TIME_BUFFER = 2 * 3600;
