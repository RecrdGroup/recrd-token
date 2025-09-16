#[test_only]
module recrd::recrd_tests;

use recrd::recrd::{Self, RECRD, RecrdTreasury, RecrdAdmin};
use sui::{coin::{Coin, CoinMetadata}, test_scenario as ts, test_utils::{destroy, assert_eq}};

const SENDER: address = @0x1;

#[test]
fun test_init() {
    let mut scenario = ts::begin(SENDER);

    recrd::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let coin_metadata = scenario.take_shared<CoinMetadata<RECRD>>();
    let recrd_treasury = scenario.take_shared<RecrdTreasury>();

    assert_eq(coin_metadata.get_decimals(), recrd::decimals());
    assert_eq(coin_metadata.get_symbol(), recrd::symbol().to_ascii_string());
    assert_eq(coin_metadata.get_name(), recrd::name().to_string());
    assert_eq(coin_metadata.get_icon_url(), option::none());
    assert_eq(coin_metadata.get_description(), b"".to_string());
    assert_eq(
        recrd_treasury.treasury_cap_for_test().total_supply(),
        recrd::total_supply_for_test(),
    );
    assert_eq(recrd_treasury.total_supply(), recrd::total_supply_for_test());

    let recrd_coin = scenario.take_from_address<Coin<RECRD>>(@multisig);
    let recrd_admin = scenario.take_from_address<RecrdAdmin>(@multisig);

    assert_eq(recrd_coin.burn_for_testing(), recrd::total_supply_for_test());

    destroy(recrd_admin);
    destroy(recrd_treasury);
    destroy(coin_metadata);
    destroy(scenario);
}

#[test]
fun test_admin_functions() {
    let mut scenario = ts::begin(SENDER);

    recrd::init_for_test(scenario.ctx());

    scenario.next_tx(@multisig);

    let mut coin_metadata = scenario.take_shared<CoinMetadata<RECRD>>();
    let recrd_treasury = scenario.take_shared<RecrdTreasury>();
    let recrd_admin = scenario.take_from_sender<RecrdAdmin>();

    let new_description = b"Recrd is a token for the Recrd ecosystem".to_string();

    recrd_treasury.update_description(&mut coin_metadata, &recrd_admin, new_description);

    assert_eq(coin_metadata.get_description(), new_description);

    let new_icon_url = b"https://recrd.com/icon.png".to_ascii_string();

    recrd_treasury.update_icon_url(&mut coin_metadata, &recrd_admin, new_icon_url);

    assert_eq(coin_metadata.get_icon_url().destroy_some().inner_url(), new_icon_url);

    let new_name = b"Recrd".to_string();

    recrd_treasury.update_name(&mut coin_metadata, &recrd_admin, new_name);

    assert_eq(coin_metadata.get_name(), new_name);

    let new_symbol = b"RCD".to_ascii_string();

    recrd_treasury.update_symbol(&mut coin_metadata, &recrd_admin, new_symbol);

    assert_eq(coin_metadata.get_symbol(), new_symbol);

    destroy(recrd_admin);
    destroy(recrd_treasury);
    destroy(coin_metadata);
    destroy(scenario);
}
