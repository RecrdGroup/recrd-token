module recrd_staking::recrd_staking_errors;

#[test_only]
const EAccountAlreadyExists: u64 = 0;

#[test_only]
const EZeroStake: u64 = 1;

#[test_only]
const EInvalidUnstake: u64 = 2;

public(package) macro fun account_already_exists(): u64 {
    0
}

public(package) macro fun zero_stake(): u64 {
    1
}

public(package) macro fun invalid_unstake(): u64 {
    2
}
