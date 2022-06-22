from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem

func coordinates_to_felt(x, y) -> (coordinate_felt):
    return (x + 32 * y)
end

func felt_to_coordinates{range_check_ptr}(coordinate_felt) -> (x, y):
    let (y, x) = unsigned_div_rem(coordinate_felt, 32)
    return (x=x, y=y)
end

func axis_coordinate_shortstring{range_check_ptr}(c) -> (coordinate_string):
    with_attr error_message("Coordinate must be between 0 and 32. Got: {c}."):
        assert_nn_le(c, 32)
    end
    if c == 0:
        return ('0')
    end
    if c == 1:
        return ('10')
    end
    if c == 2:
        return ('20')
    end
    if c == 3:
        return ('30')
    end
    if c == 4:
        return ('40')
    end
    if c == 5:
        return ('50')
    end
    if c == 6:
        return ('60')
    end
    if c == 7:
        return ('70')
    end
    if c == 8:
        return ('80')
    end
    if c == 9:
        return ('90')
    end
    if c == 10:
        return ('100')
    end
    if c == 11:
        return ('110')
    end
    if c == 12:
        return ('120')
    end
    if c == 13:
        return ('130')
    end
    if c == 14:
        return ('140')
    end
    if c == 15:
        return ('150')
    end
    if c == 16:
        return ('160')
    end
    if c == 17:
        return ('170')
    end
    if c == 18:
        return ('180')
    end
    if c == 19:
        return ('190')
    end
    if c == 20:
        return ('200')
    end
    if c == 21:
        return ('210')
    end
    if c == 22:
        return ('220')
    end
    if c == 23:
        return ('230')
    end
    if c == 24:
        return ('240')
    end
    if c == 25:
        return ('250')
    end
    if c == 26:
        return ('260')
    end
    if c == 27:
        return ('270')
    end
    if c == 28:
        return ('280')
    end
    if c == 29:
        return ('290')
    end
    if c == 30:
        return ('300')
    end
    if c == 31:
        return ('310')
    end
    if c == 32:
        return ('320')
    end
    return ('0')
end
