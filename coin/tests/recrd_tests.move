#[test_only]
module recrd::recrd_tests;

use recrd::recrd::{Self, Recrd};
use std::unit_test::assert_eq;
use sui::{
    coin::Coin,
    coin_registry::{Self, Currency, MetadataCap},
    package::Publisher,
    test_scenario as ts,
    test_utils::destroy
};

const SENDER: address = @0x0;

#[test]
fun test_end_to_end() {
    let mut scenario = ts::begin(SENDER);

    let mut coin_registry = coin_registry::create_coin_data_registry_for_testing(scenario.ctx());

    recrd::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let recrd = scenario.take_shared<Recrd>();

    // publisher was claimed and sent to multisig
    let publisher = scenario.take_from_address<Publisher>(@multisig);
    destroy(publisher);

    assert_eq!(coin_registry.exists<Recrd>(), false);

    // Create coin
    recrd.new(&mut coin_registry, scenario.ctx());

    assert_eq!(coin_registry.exists<Recrd>(), true);

    scenario.next_tx(SENDER);

    let currency = scenario.take_shared<Currency<Recrd>>();

    assert_eq!(currency.is_metadata_cap_claimed(), true);
    assert_eq!(currency.is_supply_fixed(), true);
    assert_eq!(currency.total_supply(), option::some(recrd::total_supply()));
    assert_eq!(currency.is_regulated(), false);
    assert_eq!(currency.is_supply_burn_only(), false);

    let metadata_cap = scenario.take_from_address<MetadataCap<Recrd>>(@multisig);

    assert_eq!(object::id(&metadata_cap), *currency.metadata_cap_id().borrow());

    assert_eq!(currency.decimals(), recrd::decimals());
    assert_eq!(currency.symbol(), recrd::symbol().to_string());
    assert_eq!(currency.name(), recrd::name().to_string());
    assert_eq!(currency.icon_url(), b"".to_string());
    assert_eq!(currency.description(), b"".to_string());

    let recrd_coin = scenario.take_from_address<Coin<Recrd>>(@multisig);

    assert_eq!(recrd_coin.burn_for_testing(), *currency.total_supply().borrow());

    destroy(metadata_cap);
    destroy(currency);
    destroy(coin_registry);
    destroy(scenario);
}
