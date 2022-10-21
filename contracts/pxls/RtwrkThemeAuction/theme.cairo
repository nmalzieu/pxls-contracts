%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.find_element import find_element
from starkware.cairo.common.alloc import alloc

from caistring.str import literal_concat_known_length_dangerous

func assert_theme_valid_and_pack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    characters_array_len: felt, characters_array: felt*
) -> (theme_len: felt, theme: felt*) {
    alloc_locals;
    // First validate the theme i.e. array of single whitelisted characters
    assert_whitelisted_characters(characters_array_len, characters_array);
    let (encoded_characters_array_len, encoded_characters_array: felt*) = encode_spaces(
        characters_array_len, characters_array
    );
    // At this point we know we only have single chars in the array so we can pack them by 31
    let (theme: felt*) = alloc();
    let (theme_len) = pack_theme(
        encoded_characters_array_len, encoded_characters_array, 0, 0, 0, theme
    );
    return (theme_len=theme_len, theme=theme);
}

func pack_theme{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    characters_array_len: felt,
    characters_array: felt*,
    current_packed_count: felt,
    current_packed_value: felt,
    theme_len: felt,
    theme: felt*,
) -> (theme_len: felt) {
    // If we're at last character, we're done
    if (characters_array_len == 0) {
        // If we were a multiple of 31 chars we're done
        if (current_packed_value == 0) {
            return (theme_len=theme_len);
        } else {
            // If not let's not forget to add the last packed value
            assert theme[theme_len] = current_packed_value;
            return (theme_len=theme_len + 1);
        }
    }
    let character = characters_array[0];
    // We know current value is less than 31 chars so we can pack 1 more
    let (new_packed_value) = literal_concat_known_length_dangerous(
        current_packed_value, character, 1
    );
    let new_packed_count = current_packed_count + 1;
    // If we got to 31 chars, let's add to the theme array
    if (new_packed_count == 31) {
        assert theme[theme_len] = new_packed_value;
        return pack_theme(
            characters_array_len - 1, characters_array + 1, 0, 0, theme_len + 1, theme
        );
    }
    // If not let's continue the loop
    return pack_theme(
        characters_array_len - 1,
        characters_array + 1,
        new_packed_count,
        new_packed_value,
        theme_len,
        theme,
    );
}

func assert_whitelisted_characters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    array_len: felt, array: felt*
) -> () {
    if (array_len == 0) {
        return ();
    }
    assert_whitelisted_character(array[0]);
    return assert_whitelisted_characters(array_len - 1, array + 1);
}

func assert_whitelisted_character{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    string: felt
) -> () {
    let (whitelisted_characters_location) = get_label_location(whitelisted_characters_label);
    let whitelisted_characters = cast(whitelisted_characters_location, felt*);

    with_attr error_message("Could not find {string} in whitelisted characters") {
        find_element(array_ptr=whitelisted_characters, elm_size=1, n_elms=83, key=string);
    }

    return ();

    whitelisted_characters_label:
    dw 'A';
    dw 'B';
    dw 'C';
    dw 'D';
    dw 'E';
    dw 'F';
    dw 'G';
    dw 'H';
    dw 'I';
    dw 'J';
    dw 'K';
    dw 'L';
    dw 'M';
    dw 'N';
    dw 'O';
    dw 'P';
    dw 'Q';
    dw 'R';
    dw 'S';
    dw 'T';
    dw 'U';
    dw 'V';
    dw 'W';
    dw 'X';
    dw 'Y';
    dw 'Z';
    dw 'a';
    dw 'b';
    dw 'c';
    dw 'd';
    dw 'e';
    dw 'f';
    dw 'g';
    dw 'h';
    dw 'i';
    dw 'j';
    dw 'k';
    dw 'l';
    dw 'm';
    dw 'n';
    dw 'o';
    dw 'p';
    dw 'q';
    dw 'r';
    dw 's';
    dw 't';
    dw 'u';
    dw 'v';
    dw 'w';
    dw 'x';
    dw 'y';
    dw 'z';
    dw '0';
    dw '1';
    dw '2';
    dw '3';
    dw '4';
    dw '5';
    dw '6';
    dw '7';
    dw '8';
    dw '9';
    dw '-';
    dw '.';
    dw '_';
    dw '~';
    dw ':';
    dw '/';
    dw '?';
    dw '[';
    dw ']';
    dw '@';
    dw '!';
    dw '$';
    dw '&';
    dw 39;  // ' character
    dw '(';
    dw ')';
    dw '*';
    dw ' ';
    dw ',';
    dw ';';
    dw '=';
}

func encode_spaces{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    characters_array_len: felt, characters_array: felt*
) -> (encoded_characters_array_len: felt, encoded_characters_array: felt*) {
    let (encoded_characters_array: felt*) = alloc();
    return _encode_spaces(characters_array_len, characters_array, 0, encoded_characters_array);
}

func _encode_spaces{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    characters_array_len: felt,
    characters_array: felt*,
    encoded_characters_array_len,
    encoded_characters_array: felt*,
) -> (encoded_characters_array_len: felt, encoded_characters_array: felt*) {
    if (characters_array_len == 0) {
        return (
            encoded_characters_array_len=encoded_characters_array_len,
            encoded_characters_array=encoded_characters_array,
        );
    }
    let character = characters_array[0];
    if (character == ' ') {
        assert encoded_characters_array[encoded_characters_array_len] = '%';
        assert encoded_characters_array[encoded_characters_array_len + 1] = '2';
        assert encoded_characters_array[encoded_characters_array_len + 2] = '0';
        return _encode_spaces(
            characters_array_len - 1,
            characters_array + 1,
            encoded_characters_array_len + 3,
            encoded_characters_array,
        );
    } else {
        assert encoded_characters_array[encoded_characters_array_len] = character;
        return _encode_spaces(
            characters_array_len - 1,
            characters_array + 1,
            encoded_characters_array_len + 1,
            encoded_characters_array,
        );
    }
}
