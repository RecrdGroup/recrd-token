module recrd_staking::recrd_staking_tests;

use recrd_staking::{
    recrd_staking::{Self, RecrdStaking, RecrdStakingAccount},
    recrd_staking_errors,
    recrd_staking_events::{Self, Event, NewAccount, Stake, Unstake}
};
use sui::{
    coin,
    display::Display,
    event,
    package::Publisher,
    test_scenario as ts,
    test_utils::{destroy, assert_eq}
};

const SENDER: address = @0x1;

const OWNER: address = @0x2;

#[test]
fun test_init() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let recrd_staking = scenario.take_shared<RecrdStaking>();
    let publisher = scenario.take_from_address<Publisher>(@multisig);
    let display = scenario.take_from_address<Display<RecrdStakingAccount>>(@multisig);

    destroy(publisher);
    destroy(display);
    destroy(recrd_staking);
    destroy(scenario);
}

#[test]
fun test_new() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let mut recrd_staking = scenario.take_shared<RecrdStaking>();

    assert_eq(recrd_staking.staking_account_of(OWNER), option::none());

    let account = recrd_staking.new(OWNER, scenario.ctx());

    let account_address = object::id_address(&account);

    assert_eq(recrd_staking.staking_account_of(OWNER), option::some(account_address));

    assert_eq(account.owner(), OWNER);

    account.transfer_to_owner();

    assert_eq(event::num_events(), 1);

    let new_account_events = event::events_by_type<Event<NewAccount>>();

    assert_eq(
        new_account_events[0],
        recrd_staking_events::new_account_event(account_address, OWNER),
    );

    assert_eq(recrd_staking.staking_account_of(SENDER), option::none());

    scenario.next_tx(OWNER);

    let account = scenario.take_from_sender<RecrdStakingAccount>();

    assert_eq(object::id_address(&account), account_address);

    destroy(account);
    destroy(recrd_staking);
    destroy(scenario);
}

#[
    test,
    expected_failure(
        abort_code = recrd_staking_errors::EAccountAlreadyExists,
        location = recrd_staking,
    ),
]
fun test_new_account_already_exists() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let mut recrd_staking = scenario.take_shared<RecrdStaking>();

    let _account = recrd_staking.new(OWNER, scenario.ctx());
    let _account2 = recrd_staking.new(OWNER, scenario.ctx());

    abort
}

#[test]
fun test_stake() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let mut recrd_staking = scenario.take_shared<RecrdStaking>();

    let mut account = recrd_staking.new(SENDER, scenario.ctx());

    assert_eq(account.stake_amount(), 0);

    account.stake(coin::mint_for_testing(100, scenario.ctx()), scenario.ctx());

    assert_eq(account.stake_amount(), 100);

    assert_eq(event::num_events(), 2);

    let stake_events = event::events_by_type<Event<Stake>>();

    assert_eq(
        stake_events[0],
        recrd_staking_events::stake_event(100, object::id_address(&account), SENDER, 100),
    );

    account.stake(coin::mint_for_testing(50, scenario.ctx()), scenario.ctx());

    assert_eq(account.stake_amount(), 150);

    assert_eq(event::num_events(), 3);

    let stake_events = event::events_by_type<Event<Stake>>();

    assert_eq(
        stake_events[1],
        recrd_staking_events::stake_event(50, object::id_address(&account), SENDER, 150),
    );

    account.transfer_to_owner();

    destroy(recrd_staking);
    destroy(scenario);
}

#[test, expected_failure(abort_code = recrd_staking_errors::EZeroStake, location = recrd_staking)]
fun test_stake_zero_stake() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let mut recrd_staking = scenario.take_shared<RecrdStaking>();

    let mut account = recrd_staking.new(SENDER, scenario.ctx());

    account.stake(coin::mint_for_testing(0, scenario.ctx()), scenario.ctx());

    abort
}

#[test]
fun test_unstake() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let mut recrd_staking = scenario.take_shared<RecrdStaking>();

    let mut account = recrd_staking.new(SENDER, scenario.ctx());

    account.stake(coin::mint_for_testing(100, scenario.ctx()), scenario.ctx());

    assert_eq(account.stake_amount(), 100);

    let stake = account.unstake(30, scenario.ctx());

    assert_eq(stake.burn_for_testing(), 30);

    assert_eq(account.stake_amount(), 70);

    assert_eq(event::num_events(), 3);

    let unstake_events = event::events_by_type<Event<Unstake>>();

    assert_eq(
        unstake_events[0],
        recrd_staking_events::unstake_event(30, object::id_address(&account), SENDER, 70),
    );

    let stake = account.unstake(70, scenario.ctx());

    assert_eq(stake.burn_for_testing(), 70);

    assert_eq(account.stake_amount(), 0);

    assert_eq(event::num_events(), 4);

    let unstake_events = event::events_by_type<Event<Unstake>>();

    assert_eq(
        unstake_events[1],
        recrd_staking_events::unstake_event(70, object::id_address(&account), SENDER, 0),
    );

    account.transfer_to_owner();

    destroy(recrd_staking);
    destroy(scenario);
}

#[
    test,
    expected_failure(
        abort_code = recrd_staking_errors::EInvalidUnstake,
        location = recrd_staking,
    ),
]
fun test_unstake_zero_unstake() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let mut recrd_staking = scenario.take_shared<RecrdStaking>();

    let mut account = recrd_staking.new(SENDER, scenario.ctx());

    account.stake(coin::mint_for_testing(100, scenario.ctx()), scenario.ctx());

    let _stake = account.unstake(0, scenario.ctx());

    abort
}

#[
    test,
    expected_failure(
        abort_code = recrd_staking_errors::EInvalidUnstake,
        location = recrd_staking,
    ),
]
fun test_unstake_exceed_unstake() {
    let mut scenario = ts::begin(SENDER);

    recrd_staking::init_for_test(scenario.ctx());

    scenario.next_tx(SENDER);

    let mut recrd_staking = scenario.take_shared<RecrdStaking>();

    let mut account = recrd_staking.new(SENDER, scenario.ctx());

    account.stake(coin::mint_for_testing(100, scenario.ctx()), scenario.ctx());

    let _stake = account.unstake(101, scenario.ctx());

    abort
}
