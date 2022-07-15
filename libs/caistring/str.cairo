%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (unsigned_div_rem, sign, assert_nn, abs_value, assert_not_zero, sqrt)
from starkware.cairo.common.math_cmp import (is_nn, is_le, is_not_zero)
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc

from caistring.array import array_concat

#
# Define the string struct
#
struct Str:
    member arr_len : felt
    member arr : felt*
end

#
# Concatenante two literals (literal1 + literal2)
# (function does not check if final length <= 31 char)
#
func literal_concat_known_length_dangerous {} (
        literal1 : felt,
        literal2 : felt,
        len2 : felt
    ) -> (
        res : felt
    ):

    # left shift literal1 by 256^len2 = 2^(8*len2) = multiply by pow2(8*len2)
    let (multiplier) = pow2 (8 * len2)
    let res = literal1 * multiplier + literal2

    return (res)
end

#
# Concatenate two strings
#
func str_concat {range_check_ptr} (
        str1 : Str,
        str2 : Str
    ) -> (
        res : Str
    ):

    let (
        arr_res_len : felt,
        arr_res : felt*
    ) = array_concat (
        arr1_len = str1.arr_len,
        arr1 = str1.arr,
        arr2_len = str2.arr_len,
        arr2 = str2.arr
    )

    return ( Str(arr_res_len, arr_res) )
end

#
# Concatenate an array of Str's into one Str
#
func str_concat_array {range_check_ptr} (
        arr_str_len : felt,
        arr_str : Str*
    ) -> (
        res : Str
    ):
    alloc_locals

    let (arr_init) = alloc()
    let (arr_len, arr) = _recurse_str_concat_array (
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        arr_len = 0,
        arr = arr_init,
        idx = 0
    )

    let res = Str (arr_len, arr)
    return (res)
end


func _recurse_str_concat_array {range_check_ptr} (
        arr_str_len : felt,
        arr_str : Str*,
        arr_len : felt,
        arr : felt*,
        idx : felt
    ) -> (
        arr_final_len : felt,
        arr_final : felt*
    ):

    if idx == arr_str_len:
        return (arr_len, arr)
    end

    let (
        arr_nxt_len : felt,
        arr_nxt : felt*
    ) = array_concat (
        arr1_len = arr_len,
        arr1 = arr,
        arr2_len = arr_str[idx].arr_len,
        arr2 = arr_str[idx].arr
    )

    #
    # Tail recursion
    #
    let (
        arr_final_len : felt,
        arr_final : felt*
    ) = _recurse_str_concat_array (
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        arr_len = arr_nxt_len,
        arr = arr_nxt,
        idx = idx + 1
    )

    return (arr_final_len, arr_final)
end

#
# Create an instance of Str from single-felt string literal
#
func str_from_literal {range_check_ptr} (
    literal : felt) -> (str : Str):

    let len = 1
    let (arr : felt*) = alloc()
    assert arr[0] = literal

    return ( Str (len,arr) )
end

#
# Create instance of Str that is empty
#
func str_empty  {range_check_ptr} (
    ) -> (str : Str):

    let len = 0
    let (arr : felt*) = alloc()

    return ( Str (len,arr) )
end

#
# Convert felt (decimal fixed point) into ascii-encoded felt representing str(felt); return a literal
# e.g. num_fp=15, scale_fp=1 => interpreted as '1.5', return (49)*(256**2) + (46)*256 + (53)
#
func literal_from_fp_number {range_check_ptr} (
        num_fp : felt,
        scale_fp : felt
    ) -> (
        literal : felt
    ):

end

#
# Same as literal_from_fp_number but return a Str instance
#
func str_from_fp_number {range_check_ptr} (
        num_fp : felt,
        scale_fp : felt
    ) -> (
        str : Str
    ):

end

#
# Convert felt (decimal integer) into ascii-encoded felt representing str(felt); return a literal
# e.g. 7 => interpreted as '7', return 55
# e.g. 77 => interpreted as '77', return 55*256 + 55 = 14135
# fail if needed more than 31 characters
#
func literal_from_number {range_check_ptr} (
    num : felt) -> (literal : felt):
    alloc_locals

    #
    # Handle special case first
    #
    if num == 0:
        return ('0')
    end

    let (arr_ascii) = alloc()
    let (
        arr_ascii_len : felt
    ) = _recurse_ascii_array_from_number (
        remain = num,
        arr_ascii_len = 0,
        arr_ascii = arr_ascii
    )

    let (ascii) = _recurse_ascii_from_ascii_array_inverse (
        ascii = 0,
        len = arr_ascii_len,
        arr = arr_ascii,
        idx = 0
    )

    return (ascii)
end

func _recurse_ascii_array_from_number {range_check_ptr} (
        remain : felt,
        arr_ascii_len : felt,
        arr_ascii : felt*
    ) -> (
        arr_ascii_final_len : felt
    ):
    alloc_locals

    if remain == 0:
        return (arr_ascii_len)
    end

    let (remain_nxt, digit) = unsigned_div_rem (remain, 10)
    let (ascii) = ascii_from_digit (digit)
    assert arr_ascii[arr_ascii_len] = ascii

    #
    # Tail recursion
    #
    let (arr_ascii_final_len) = _recurse_ascii_array_from_number (
        remain = remain_nxt,
        arr_ascii_len = arr_ascii_len + 1,
        arr_ascii = arr_ascii
    )
    return (arr_ascii_final_len)
end

func _recurse_ascii_from_ascii_array_inverse {range_check_ptr} (
        ascii : felt,
        len : felt,
        arr : felt*,
        idx : felt
    ) -> (ascii_final : felt):

    if idx == len:
        return (ascii)
    end

    let ascii_nxt = ascii * 256 + arr[len-idx-1]

    #
    # Tail recursion
    #
    let (ascii_final) = _recurse_ascii_from_ascii_array_inverse (
        ascii = ascii_nxt,
        len = len,
        arr = arr,
        idx = idx + 1
    )
    return (ascii_final)
end

#
# Same as literal_from_number but return a Str instance
#
func str_from_number {range_check_ptr} (
    num : felt) -> (str : Str):
    alloc_locals

    let (literal) = literal_from_number (num)
    let (str : Str) = str_from_literal (literal)

    return (str)
end

#
# Convert felt (decimal) to ascii-encoded felt representing str(hex(felt)), return a string;
# need to provide desired hex length as input arg
# e.g. num = 10, hexlen = 2 => returns '0A' in string
# e.g. num = 10, hexlen = 1 => returns 'A' in string
# note: particularly useful for handling MIDI format
#
func str_hex_from_number {range_check_ptr} (
        num : felt,
        hexlen : felt
    ) -> (
        str : Str
    ):

    #
    # Algorithm
    # 1. convert `num` in decimal to an array of Str(literal)
    #    e.g. convert 25 to array [str_from_literal('F'), str_from_literal('9')]
    # 2. run str_concat_array() on the array
    #



end

#
# Get ascii in decimal value from given digit
# note: does not check if input is indeed a digit
#
func ascii_from_digit (digit : felt) -> (ascii : felt):
    return (digit + '0')
end

#
# Concat a Str with a literal, and return a Str
#
func str_concat_literal {range_check_ptr} (str : Str, literal : felt) -> (res : Str):

    let (str_literal) = str_from_literal (literal)
    let (res) = str_concat (str, str_literal)

    return (res)
end

#
# Compute power of 2
# taken from Warp's src
# https://github.com/NethermindEth/warp/blob/develop/src/warp/cairo-src/evm/pow2.cairo
# input range: 0~250
#
func pow2(i : felt) -> (res : felt):
    let (data_address) = get_label_location(data)
    return ([data_address + i])

    data:
    dw 1
    dw 2
    dw 4
    dw 8
    dw 16
    dw 32
    dw 64
    dw 128
    dw 256
    dw 512
    dw 1024
    dw 2048
    dw 4096
    dw 8192
    dw 16384
    dw 32768
    dw 65536
    dw 131072
    dw 262144
    dw 524288
    dw 1048576
    dw 2097152
    dw 4194304
    dw 8388608
    dw 16777216
    dw 33554432
    dw 67108864
    dw 134217728
    dw 268435456
    dw 536870912
    dw 1073741824
    dw 2147483648
    dw 4294967296
    dw 8589934592
    dw 17179869184
    dw 34359738368
    dw 68719476736
    dw 137438953472
    dw 274877906944
    dw 549755813888
    dw 1099511627776
    dw 2199023255552
    dw 4398046511104
    dw 8796093022208
    dw 17592186044416
    dw 35184372088832
    dw 70368744177664
    dw 140737488355328
    dw 281474976710656
    dw 562949953421312
    dw 1125899906842624
    dw 2251799813685248
    dw 4503599627370496
    dw 9007199254740992
    dw 18014398509481984
    dw 36028797018963968
    dw 72057594037927936
    dw 144115188075855872
    dw 288230376151711744
    dw 576460752303423488
    dw 1152921504606846976
    dw 2305843009213693952
    dw 4611686018427387904
    dw 9223372036854775808
    dw 18446744073709551616
    dw 36893488147419103232
    dw 73786976294838206464
    dw 147573952589676412928
    dw 295147905179352825856
    dw 590295810358705651712
    dw 1180591620717411303424
    dw 2361183241434822606848
    dw 4722366482869645213696
    dw 9444732965739290427392
    dw 18889465931478580854784
    dw 37778931862957161709568
    dw 75557863725914323419136
    dw 151115727451828646838272
    dw 302231454903657293676544
    dw 604462909807314587353088
    dw 1208925819614629174706176
    dw 2417851639229258349412352
    dw 4835703278458516698824704
    dw 9671406556917033397649408
    dw 19342813113834066795298816
    dw 38685626227668133590597632
    dw 77371252455336267181195264
    dw 154742504910672534362390528
    dw 309485009821345068724781056
    dw 618970019642690137449562112
    dw 1237940039285380274899124224
    dw 2475880078570760549798248448
    dw 4951760157141521099596496896
    dw 9903520314283042199192993792
    dw 19807040628566084398385987584
    dw 39614081257132168796771975168
    dw 79228162514264337593543950336
    dw 158456325028528675187087900672
    dw 316912650057057350374175801344
    dw 633825300114114700748351602688
    dw 1267650600228229401496703205376
    dw 2535301200456458802993406410752
    dw 5070602400912917605986812821504
    dw 10141204801825835211973625643008
    dw 20282409603651670423947251286016
    dw 40564819207303340847894502572032
    dw 81129638414606681695789005144064
    dw 162259276829213363391578010288128
    dw 324518553658426726783156020576256
    dw 649037107316853453566312041152512
    dw 1298074214633706907132624082305024
    dw 2596148429267413814265248164610048
    dw 5192296858534827628530496329220096
    dw 10384593717069655257060992658440192
    dw 20769187434139310514121985316880384
    dw 41538374868278621028243970633760768
    dw 83076749736557242056487941267521536
    dw 166153499473114484112975882535043072
    dw 332306998946228968225951765070086144
    dw 664613997892457936451903530140172288
    dw 1329227995784915872903807060280344576
    dw 2658455991569831745807614120560689152
    dw 5316911983139663491615228241121378304
    dw 10633823966279326983230456482242756608
    dw 21267647932558653966460912964485513216
    dw 42535295865117307932921825928971026432
    dw 85070591730234615865843651857942052864
    dw 170141183460469231731687303715884105728
    dw 340282366920938463463374607431768211456
    dw 680564733841876926926749214863536422912
    dw 1361129467683753853853498429727072845824
    dw 2722258935367507707706996859454145691648
    dw 5444517870735015415413993718908291383296
    dw 10889035741470030830827987437816582766592
    dw 21778071482940061661655974875633165533184
    dw 43556142965880123323311949751266331066368
    dw 87112285931760246646623899502532662132736
    dw 174224571863520493293247799005065324265472
    dw 348449143727040986586495598010130648530944
    dw 696898287454081973172991196020261297061888
    dw 1393796574908163946345982392040522594123776
    dw 2787593149816327892691964784081045188247552
    dw 5575186299632655785383929568162090376495104
    dw 11150372599265311570767859136324180752990208
    dw 22300745198530623141535718272648361505980416
    dw 44601490397061246283071436545296723011960832
    dw 89202980794122492566142873090593446023921664
    dw 178405961588244985132285746181186892047843328
    dw 356811923176489970264571492362373784095686656
    dw 713623846352979940529142984724747568191373312
    dw 1427247692705959881058285969449495136382746624
    dw 2854495385411919762116571938898990272765493248
    dw 5708990770823839524233143877797980545530986496
    dw 11417981541647679048466287755595961091061972992
    dw 22835963083295358096932575511191922182123945984
    dw 45671926166590716193865151022383844364247891968
    dw 91343852333181432387730302044767688728495783936
    dw 182687704666362864775460604089535377456991567872
    dw 365375409332725729550921208179070754913983135744
    dw 730750818665451459101842416358141509827966271488
    dw 1461501637330902918203684832716283019655932542976
    dw 2923003274661805836407369665432566039311865085952
    dw 5846006549323611672814739330865132078623730171904
    dw 11692013098647223345629478661730264157247460343808
    dw 23384026197294446691258957323460528314494920687616
    dw 46768052394588893382517914646921056628989841375232
    dw 93536104789177786765035829293842113257979682750464
    dw 187072209578355573530071658587684226515959365500928
    dw 374144419156711147060143317175368453031918731001856
    dw 748288838313422294120286634350736906063837462003712
    dw 1496577676626844588240573268701473812127674924007424
    dw 2993155353253689176481146537402947624255349848014848
    dw 5986310706507378352962293074805895248510699696029696
    dw 11972621413014756705924586149611790497021399392059392
    dw 23945242826029513411849172299223580994042798784118784
    dw 47890485652059026823698344598447161988085597568237568
    dw 95780971304118053647396689196894323976171195136475136
    dw 191561942608236107294793378393788647952342390272950272
    dw 383123885216472214589586756787577295904684780545900544
    dw 766247770432944429179173513575154591809369561091801088
    dw 1532495540865888858358347027150309183618739122183602176
    dw 3064991081731777716716694054300618367237478244367204352
    dw 6129982163463555433433388108601236734474956488734408704
    dw 12259964326927110866866776217202473468949912977468817408
    dw 24519928653854221733733552434404946937899825954937634816
    dw 49039857307708443467467104868809893875799651909875269632
    dw 98079714615416886934934209737619787751599303819750539264
    dw 196159429230833773869868419475239575503198607639501078528
    dw 392318858461667547739736838950479151006397215279002157056
    dw 784637716923335095479473677900958302012794430558004314112
    dw 1569275433846670190958947355801916604025588861116008628224
    dw 3138550867693340381917894711603833208051177722232017256448
    dw 6277101735386680763835789423207666416102355444464034512896
    dw 12554203470773361527671578846415332832204710888928069025792
    dw 25108406941546723055343157692830665664409421777856138051584
    dw 50216813883093446110686315385661331328818843555712276103168
    dw 100433627766186892221372630771322662657637687111424552206336
    dw 200867255532373784442745261542645325315275374222849104412672
    dw 401734511064747568885490523085290650630550748445698208825344
    dw 803469022129495137770981046170581301261101496891396417650688
    dw 1606938044258990275541962092341162602522202993782792835301376
    dw 3213876088517980551083924184682325205044405987565585670602752
    dw 6427752177035961102167848369364650410088811975131171341205504
    dw 12855504354071922204335696738729300820177623950262342682411008
    dw 25711008708143844408671393477458601640355247900524685364822016
    dw 51422017416287688817342786954917203280710495801049370729644032
    dw 102844034832575377634685573909834406561420991602098741459288064
    dw 205688069665150755269371147819668813122841983204197482918576128
    dw 411376139330301510538742295639337626245683966408394965837152256
    dw 822752278660603021077484591278675252491367932816789931674304512
    dw 1645504557321206042154969182557350504982735865633579863348609024
    dw 3291009114642412084309938365114701009965471731267159726697218048
    dw 6582018229284824168619876730229402019930943462534319453394436096
    dw 13164036458569648337239753460458804039861886925068638906788872192
    dw 26328072917139296674479506920917608079723773850137277813577744384
    dw 52656145834278593348959013841835216159447547700274555627155488768
    dw 105312291668557186697918027683670432318895095400549111254310977536
    dw 210624583337114373395836055367340864637790190801098222508621955072
    dw 421249166674228746791672110734681729275580381602196445017243910144
    dw 842498333348457493583344221469363458551160763204392890034487820288
    dw 1684996666696914987166688442938726917102321526408785780068975640576
    dw 3369993333393829974333376885877453834204643052817571560137951281152
    dw 6739986666787659948666753771754907668409286105635143120275902562304
    dw 13479973333575319897333507543509815336818572211270286240551805124608
    dw 26959946667150639794667015087019630673637144422540572481103610249216
    dw 53919893334301279589334030174039261347274288845081144962207220498432
    dw 107839786668602559178668060348078522694548577690162289924414440996864
    dw 215679573337205118357336120696157045389097155380324579848828881993728
    dw 431359146674410236714672241392314090778194310760649159697657763987456
    dw 862718293348820473429344482784628181556388621521298319395315527974912
    dw 1725436586697640946858688965569256363112777243042596638790631055949824
    dw 3450873173395281893717377931138512726225554486085193277581262111899648
    dw 6901746346790563787434755862277025452451108972170386555162524223799296
    dw 13803492693581127574869511724554050904902217944340773110325048447598592
    dw 27606985387162255149739023449108101809804435888681546220650096895197184
    dw 55213970774324510299478046898216203619608871777363092441300193790394368
    dw 110427941548649020598956093796432407239217743554726184882600387580788736
    dw 220855883097298041197912187592864814478435487109452369765200775161577472
    dw 441711766194596082395824375185729628956870974218904739530401550323154944
    dw 883423532389192164791648750371459257913741948437809479060803100646309888
    dw 1766847064778384329583297500742918515827483896875618958121606201292619776
    dw 3533694129556768659166595001485837031654967793751237916243212402585239552
    dw 7067388259113537318333190002971674063309935587502475832486424805170479104
    dw 14134776518227074636666380005943348126619871175004951664972849610340958208
    dw 28269553036454149273332760011886696253239742350009903329945699220681916416
    dw 56539106072908298546665520023773392506479484700019806659891398441363832832
    dw 113078212145816597093331040047546785012958969400039613319782796882727665664
    dw 226156424291633194186662080095093570025917938800079226639565593765455331328
    dw 452312848583266388373324160190187140051835877600158453279131187530910662656
    dw 904625697166532776746648320380374280103671755200316906558262375061821325312
    dw 1809251394333065553493296640760748560207343510400633813116524750123642650624
end