def str_to_felt(text):
    b_text = bytes(text, 'ascii')
    return int.from_bytes(b_text, "big")

def felt_to_str(felt):
    b_felt = felt.to_bytes(31, "big")
    return b_felt.decode()

def felt_to_clean_str(felt):
    return felt_to_str(felt).replace('\x00', '')

def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)