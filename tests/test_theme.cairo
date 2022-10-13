%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from pxls.RtwrkThemeAuction.theme import (
    assert_whitelisted_character,
    assert_whitelisted_characters,
    assert_theme_valid_and_pack,
)

@view
func test_assert_whitelisted_character{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    assert_whitelisted_character('A');
    assert_whitelisted_character(39);

    %{ expect_revert(error_message="Could not find 37 in whitelisted characters") %}
    assert_whitelisted_character('%');
    return ();
}

@view
func test_assert_assert_theme_chars_valid{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    let (theme: felt*) = alloc();
    assert theme[0] = 'S';
    assert theme[1] = 'u';
    assert theme[2] = 'p';

    assert_whitelisted_characters(3, theme);

    let (theme_2: felt*) = alloc();
    assert theme_2[0] = 'S';
    assert theme_2[1] = 'u';
    assert theme_2[2] = '%';

    %{ expect_revert(error_message="Could not find 37 in whitelisted characters") %}
    assert_whitelisted_characters(3, theme_2);
    return ();
}

@view
func test_assert_assert_theme_string_valid{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    let (theme: felt*) = alloc();
    assert theme[0] = 'Sup';

    %{ expect_revert(error_message="Could not find 5469552 in whitelisted characters") %}

    assert_whitelisted_characters(1, theme);
    return ();
}

@view
func test_assert_theme_valid_and_pack{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    let (theme_to_validate: felt*) = alloc();
    assert theme_to_validate[0] = 'S';
    assert theme_to_validate[1] = 'u';
    assert theme_to_validate[2] = 'p';

    let (theme_len, theme: felt*) = assert_theme_valid_and_pack(3, theme_to_validate);
    assert 1 = theme_len;
    assert 'Sup' = theme[0];

    let (theme_to_validate: felt*) = alloc();
    assert theme_to_validate[0] = 'S';
    assert theme_to_validate[1] = 'u';
    assert theme_to_validate[2] = 'p';
    assert theme_to_validate[3] = 'S';
    assert theme_to_validate[4] = 'u';
    assert theme_to_validate[5] = 'p';
    assert theme_to_validate[6] = 'S';
    assert theme_to_validate[7] = 'u';
    assert theme_to_validate[8] = 'p';
    assert theme_to_validate[9] = 'S';
    assert theme_to_validate[10] = 'u';
    assert theme_to_validate[11] = 'p';
    assert theme_to_validate[12] = 'S';
    assert theme_to_validate[13] = 'u';
    assert theme_to_validate[14] = 'p';
    assert theme_to_validate[15] = 'S';
    assert theme_to_validate[16] = 'u';
    assert theme_to_validate[17] = 'p';
    assert theme_to_validate[18] = 'S';
    assert theme_to_validate[19] = 'u';
    assert theme_to_validate[20] = 'p';
    assert theme_to_validate[21] = 'S';
    assert theme_to_validate[22] = 'u';
    assert theme_to_validate[23] = 'p';
    assert theme_to_validate[24] = 'S';
    assert theme_to_validate[25] = 'u';
    assert theme_to_validate[26] = 'p';
    assert theme_to_validate[27] = 'S';
    assert theme_to_validate[28] = 'u';
    assert theme_to_validate[29] = 'p';
    assert theme_to_validate[30] = 'S';
    assert theme_to_validate[31] = 'o';
    assert theme_to_validate[32] = '%';

    let (theme_len, theme: felt*) = assert_theme_valid_and_pack(31, theme_to_validate);
    assert 1 = theme_len;
    assert 'SupSupSupSupSupSupSupSupSupSupS' = theme[0];

    let (theme_len, theme: felt*) = assert_theme_valid_and_pack(32, theme_to_validate);
    assert 2 = theme_len;
    assert 'SupSupSupSupSupSupSupSupSupSupS' = theme[0];
    assert 'o' = theme[1];

    %{ expect_revert(error_message="Could not find 37 in whitelisted characters") %}
    assert_theme_valid_and_pack(33, theme_to_validate);

    return ();
}
