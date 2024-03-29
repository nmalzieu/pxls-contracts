from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE

func number_literal_length{range_check_ptr}(i: felt) -> (length: felt) {
    alloc_locals;
    // Returns the length of the short string representing i
    // (useful to use the literal_concat_known_length_dangerous method
    // which takes the length. If not it introduces \x00s in the strings
    // which would be ok but makes testing complicated
    // /!\ Since it's to be used with  number_to_literal_dangerous
    // we don't go over 400

    let less_than_10 = is_le(i, 9);
    let less_than_100 = is_le(i, 99);
    if (less_than_10 == TRUE) {
        return (length=1);
    }
    if (less_than_100 == TRUE) {
        return (length=2);
    }
    return (length=3);
}

func number_to_literal_dangerous(i: felt) -> (res: felt) {
    // This method returns a felt string for each integer
    // between 0 and 400 because str_from_number takes
    // a lot of steps. /!\ This prevents the NFT collection
    // to have more than 400 pixels since the pixel id is
    // part of the metadata which is text.
    let (data_address) = get_label_location(data);
    return ([data_address + i],);

    data:
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
    dw '10';
    dw '11';
    dw '12';
    dw '13';
    dw '14';
    dw '15';
    dw '16';
    dw '17';
    dw '18';
    dw '19';
    dw '20';
    dw '21';
    dw '22';
    dw '23';
    dw '24';
    dw '25';
    dw '26';
    dw '27';
    dw '28';
    dw '29';
    dw '30';
    dw '31';
    dw '32';
    dw '33';
    dw '34';
    dw '35';
    dw '36';
    dw '37';
    dw '38';
    dw '39';
    dw '40';
    dw '41';
    dw '42';
    dw '43';
    dw '44';
    dw '45';
    dw '46';
    dw '47';
    dw '48';
    dw '49';
    dw '50';
    dw '51';
    dw '52';
    dw '53';
    dw '54';
    dw '55';
    dw '56';
    dw '57';
    dw '58';
    dw '59';
    dw '60';
    dw '61';
    dw '62';
    dw '63';
    dw '64';
    dw '65';
    dw '66';
    dw '67';
    dw '68';
    dw '69';
    dw '70';
    dw '71';
    dw '72';
    dw '73';
    dw '74';
    dw '75';
    dw '76';
    dw '77';
    dw '78';
    dw '79';
    dw '80';
    dw '81';
    dw '82';
    dw '83';
    dw '84';
    dw '85';
    dw '86';
    dw '87';
    dw '88';
    dw '89';
    dw '90';
    dw '91';
    dw '92';
    dw '93';
    dw '94';
    dw '95';
    dw '96';
    dw '97';
    dw '98';
    dw '99';
    dw '100';
    dw '101';
    dw '102';
    dw '103';
    dw '104';
    dw '105';
    dw '106';
    dw '107';
    dw '108';
    dw '109';
    dw '110';
    dw '111';
    dw '112';
    dw '113';
    dw '114';
    dw '115';
    dw '116';
    dw '117';
    dw '118';
    dw '119';
    dw '120';
    dw '121';
    dw '122';
    dw '123';
    dw '124';
    dw '125';
    dw '126';
    dw '127';
    dw '128';
    dw '129';
    dw '130';
    dw '131';
    dw '132';
    dw '133';
    dw '134';
    dw '135';
    dw '136';
    dw '137';
    dw '138';
    dw '139';
    dw '140';
    dw '141';
    dw '142';
    dw '143';
    dw '144';
    dw '145';
    dw '146';
    dw '147';
    dw '148';
    dw '149';
    dw '150';
    dw '151';
    dw '152';
    dw '153';
    dw '154';
    dw '155';
    dw '156';
    dw '157';
    dw '158';
    dw '159';
    dw '160';
    dw '161';
    dw '162';
    dw '163';
    dw '164';
    dw '165';
    dw '166';
    dw '167';
    dw '168';
    dw '169';
    dw '170';
    dw '171';
    dw '172';
    dw '173';
    dw '174';
    dw '175';
    dw '176';
    dw '177';
    dw '178';
    dw '179';
    dw '180';
    dw '181';
    dw '182';
    dw '183';
    dw '184';
    dw '185';
    dw '186';
    dw '187';
    dw '188';
    dw '189';
    dw '190';
    dw '191';
    dw '192';
    dw '193';
    dw '194';
    dw '195';
    dw '196';
    dw '197';
    dw '198';
    dw '199';
    dw '200';
    dw '201';
    dw '202';
    dw '203';
    dw '204';
    dw '205';
    dw '206';
    dw '207';
    dw '208';
    dw '209';
    dw '210';
    dw '211';
    dw '212';
    dw '213';
    dw '214';
    dw '215';
    dw '216';
    dw '217';
    dw '218';
    dw '219';
    dw '220';
    dw '221';
    dw '222';
    dw '223';
    dw '224';
    dw '225';
    dw '226';
    dw '227';
    dw '228';
    dw '229';
    dw '230';
    dw '231';
    dw '232';
    dw '233';
    dw '234';
    dw '235';
    dw '236';
    dw '237';
    dw '238';
    dw '239';
    dw '240';
    dw '241';
    dw '242';
    dw '243';
    dw '244';
    dw '245';
    dw '246';
    dw '247';
    dw '248';
    dw '249';
    dw '250';
    dw '251';
    dw '252';
    dw '253';
    dw '254';
    dw '255';
    dw '256';
    dw '257';
    dw '258';
    dw '259';
    dw '260';
    dw '261';
    dw '262';
    dw '263';
    dw '264';
    dw '265';
    dw '266';
    dw '267';
    dw '268';
    dw '269';
    dw '270';
    dw '271';
    dw '272';
    dw '273';
    dw '274';
    dw '275';
    dw '276';
    dw '277';
    dw '278';
    dw '279';
    dw '280';
    dw '281';
    dw '282';
    dw '283';
    dw '284';
    dw '285';
    dw '286';
    dw '287';
    dw '288';
    dw '289';
    dw '290';
    dw '291';
    dw '292';
    dw '293';
    dw '294';
    dw '295';
    dw '296';
    dw '297';
    dw '298';
    dw '299';
    dw '300';
    dw '301';
    dw '302';
    dw '303';
    dw '304';
    dw '305';
    dw '306';
    dw '307';
    dw '308';
    dw '309';
    dw '310';
    dw '311';
    dw '312';
    dw '313';
    dw '314';
    dw '315';
    dw '316';
    dw '317';
    dw '318';
    dw '319';
    dw '320';
    dw '321';
    dw '322';
    dw '323';
    dw '324';
    dw '325';
    dw '326';
    dw '327';
    dw '328';
    dw '329';
    dw '330';
    dw '331';
    dw '332';
    dw '333';
    dw '334';
    dw '335';
    dw '336';
    dw '337';
    dw '338';
    dw '339';
    dw '340';
    dw '341';
    dw '342';
    dw '343';
    dw '344';
    dw '345';
    dw '346';
    dw '347';
    dw '348';
    dw '349';
    dw '350';
    dw '351';
    dw '352';
    dw '353';
    dw '354';
    dw '355';
    dw '356';
    dw '357';
    dw '358';
    dw '359';
    dw '360';
    dw '361';
    dw '362';
    dw '363';
    dw '364';
    dw '365';
    dw '366';
    dw '367';
    dw '368';
    dw '369';
    dw '370';
    dw '371';
    dw '372';
    dw '373';
    dw '374';
    dw '375';
    dw '376';
    dw '377';
    dw '378';
    dw '379';
    dw '380';
    dw '381';
    dw '382';
    dw '383';
    dw '384';
    dw '385';
    dw '386';
    dw '387';
    dw '388';
    dw '389';
    dw '390';
    dw '391';
    dw '392';
    dw '393';
    dw '394';
    dw '395';
    dw '396';
    dw '397';
    dw '398';
    dw '399';
    dw '400';
}
